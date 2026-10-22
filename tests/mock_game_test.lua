-- End-to-end test of main.lua against a fake version of the game's plugin API.
--
-- Run from the repository root (CI uses Lua 5.4):
--     lua5.4 tests/mock_game_test.lua
--
-- The fakes only implement what the plugin uses, with the names documented at
-- developer.runescape.com. Reading an unknown API member, or setting an
-- undocumented component property, raises an error, so the test also guards
-- against using APIs that don't exist.
--
-- Where the real beta client behaved differently from the docs, the fakes copy
-- the real behaviour (observed October 22nd, 2026): List:Clear() leaves old
-- rows behind, and duplicate entry IDs are rejected.
--
-- Scenario: log in, open the panel, search, select and mark a ring, filter to
-- "Not discovered yet", open a fake travel log window, then let the game's
-- travel-log variables arrive.

package.path = "fairy-ring-codes/?.lua;" .. package.path

local failures = 0
local function check(condition, message)
    if not condition then
        failures = failures + 1
        print("FAIL: " .. message)
    end
end

local function strict(name, fields)
    return setmetatable(fields, {
        __index = function(_, key)
            error("plugin used unknown API member " .. name .. "." .. tostring(key), 2)
        end,
    })
end

--------------------------------------------------------------------------------
-- Events
--------------------------------------------------------------------------------

local subscribers = {}
local function fakeEvent(eventName)
    subscribers[eventName] = {}
    return strict("Event." .. eventName, {
        Subscribe = function(refName, callback) subscribers[eventName][refName] = callback end,
        Unsubscribe = function(refName) subscribers[eventName][refName] = nil end,
    })
end
local function fire(eventName, payload)
    for _, callback in pairs(subscribers[eventName]) do
        callback(payload)
    end
end

Event = strict("Event", {
    ServerLogic = fakeEvent("ServerLogic"),
    VarTransmit = fakeEvent("VarTransmit"),
    ContentLayerReady = fakeEvent("ContentLayerReady"),
})

--------------------------------------------------------------------------------
-- UI components
--------------------------------------------------------------------------------

-- Properties the plugin may set, from the Component, Text, InputField, List
-- and Button doc pages.
local DOCUMENTED_PROPERTIES = {
    Layer = {},
    Text = { content = true, font = true, maxLines = true, hidden = true },
    InputField = { content = true, emptyText = true, stylesheetID = true },
    List = { stylesheetID = true, dropdownMaxVisibleEntries = true },
    Button = { label = true, stylesheetID = true, hidden = true },
}

local components = {}
local nextRowId = 5000 -- SetEntries row IDs, deliberately unlike the plugin's own
local function fakeComponent(kind)
    local state = { kind = kind, hooks = {}, visibleGlobal = true, entries = {}, selected = nil }
    local methods = {}
    function methods.SetPos(_, ...) state.pos = { ... } end
    function methods.SetSize(_, ...) state.size = { ... } end
    function methods.AlignTo(_, ...) end
    function methods.MoveToFront(_) end
    function methods.Subscribe(_, hook, callback) state.hooks[hook] = callback end
    if kind == "List" then
        function methods.Add(_, label, entryId)
            for _, entry in ipairs(state.entries) do
                if entry.id == entryId then return false end -- IDs must be unique
            end
            table.insert(state.entries, { label = label, text = label, id = entryId })
            return true
        end
        -- Mimics what the beta client appeared to do on October 22nd, 2026:
        -- Clear() left the old rows behind. The plugin must use SetEntries.
        function methods.Clear(_) end
        -- SetEntries(labels): clears, then adds rows with auto-incrementing IDs.
        function methods.SetEntries(_, labels)
            state.entries, state.selected = {}, nil
            for _, label in ipairs(labels) do
                nextRowId = nextRowId + 1
                table.insert(state.entries, { label = label, text = label, id = nextRowId })
            end
            return true
        end
        function methods.HasEntry(_, entryId)
            for _, entry in ipairs(state.entries) do
                if entry.id == entryId then return true end
            end
            return false
        end
        function methods.SetEntrySelected(_, entryId, selected) state.selected = selected and entryId or nil end
    end
    local component = setmetatable({}, {
        __index = function(_, key)
            if methods[key] then return methods[key] end
            if key == "selectedEntries" then
                return state.selected and { { id = state.selected } } or {}
            end
            return state[key]
        end,
        __newindex = function(_, key, value)
            if not DOCUMENTED_PROPERTIES[kind][key] then
                error("plugin set undocumented property " .. kind .. "." .. tostring(key), 2)
            end
            state[key] = value
        end,
    })
    table.insert(components, component)
    return component
end

local function constructor(kind)
    return strict("ui." .. kind, { new = function() return fakeComponent(kind) end })
end

-- A fake travel log window: a list whose rows are text components, nested
-- one level down, as a real interface would be.
local travelLogOpen = false
local function fakeRow(text)
    return { content = text }
end
local fakeTravelLog = {
    IterateStaticComponents = function(_, callback)
        local list = {
            content = "",
            IterateStaticComponents = function() end,
            IterateDynamicComponents = function(_, rowCallback)
                for _, row in ipairs({ fakeRow("A I Q"), fakeRow("Asgarnia: Mudskipper Point"),
                                       fakeRow("C K S"), fakeRow("Canifis"), fakeRow("Zanaris") }) do
                    if rowCallback(row) then return end
                end
            end,
        }
        callback(list)
    end,
}

ui = strict("ui", {
    Interfaces = strict("ui.Interfaces", {
        GetInterface = function(_, interfaceId)
            if travelLogOpen and interfaceId == 999 then return fakeTravelLog end
            return nil
        end,
        GetComponent = function() return nil end,
    }),
    Text = constructor("Text"),
    InputField = constructor("InputField"),
    List = constructor("List"),
    Button = constructor("Button"),
    AlignMode = strict("ui.AlignMode", { TOPLEFT = 0, CENTRE = 1, BOTTOMRIGHT = 2, JUSTIFY = 3 }),
    Hook = strict("ui.Hook", {
        ONBUTTONPRESSED = "ONBUTTONPRESSED",
        ONCONTENTCHANGED = "ONCONTENTCHANGED",
        ONSELECTIONCHANGED = "ONSELECTIONCHANGED",
    }),
})

id = strict("id", {
    Font = strict("id.Font", { MUSEO_SANS_15PT_REGULAR = 1 }),
    StyleSheet = strict("id.StyleSheet", {
        INPUT_DEFAULT = 1, DROPDOWN_DEFAULT = 2, BUTTON_DEFAULT = 3,
    }),
})

--------------------------------------------------------------------------------
-- Player and storage
--------------------------------------------------------------------------------

local loggedIn = false
Player = strict("Player", {
    IsAvailable = function() return loggedIn end,
    GetEntity = function() return { displayName = "CloudGiraffe" } end,
})

local database = {}
PersistentDB = strict("PersistentDB", {
    GetStructuredData = function(_, key) return database[key] end,
    SetStructuredData = function(_, key, value) database[key] = value return true end,
})

-- Travel-log varbits. Unreadable until gameVarsReady is set, like before login.
local gameVarsReady = false
local gameVarbits = { [-12101] = 1, [-12142] = 1 } -- BJQ and DLR
var = strict("var", {
    VarPlayer = strict("var.VarPlayer", {
        FromID = function(variableId)
            if not gameVarsReady then error("not available yet") end
            return { value = gameVarbits[variableId] or 0 }
        end,
    }),
})

--------------------------------------------------------------------------------
-- Run the plugin
--------------------------------------------------------------------------------

dofile("fairy-ring-codes/main.lua")

loggedIn = true
fire("ServerLogic", nil)

local root = fakeComponent("Layer")
fire("ContentLayerReady", { component = root })

local function find(kind, predicate)
    for _, component in ipairs(components) do
        if component.kind == kind and (predicate == nil or predicate(component)) then
            return component
        end
    end
end
local search = find("InputField")
local filterList = find("List", function(c) return c.dropdownMaxVisibleEntries ~= 0 end)
local ringList = find("List", function(c) return c.dropdownMaxVisibleEntries == 0 end)
local button = find("Button")
local texts = {}
for _, component in ipairs(components) do
    if component.kind == "Text" then table.insert(texts, component) end
end
local summary, details = texts[2], texts[3]

check(#filterList.entries == 7, "filter dropdown has 7 choices")
check(filterList.entries[1].label == "All rings", "filter choices keep their order")
check(#ringList.entries == 59, "all 56 rings plus 3 multi-code destinations are listed (got "
    .. #ringList.entries .. ")")
check(button.hidden == true, "button hidden until a ring is selected")

-- Search for "dk".
search.content = "dk"
search.hooks.ONCONTENTCHANGED(search, "CONTENT_CHANGE", "dk")
check(#ringList.entries == 4, "searching 'dk' shows 4 rings")

-- Select Edgeville (DKR).
local edgeville
for _, entry in ipairs(ringList.entries) do
    if string.find(entry.label, "DKR", 1, true) == 1 then edgeville = entry end
end
ringList:SetEntrySelected(edgeville.id, true)
ringList.hooks.ONSELECTIONCHANGED(ringList, edgeville.id, 1)
check(string.find(details.content, "Edgeville", 1, true) ~= nil, "details show Edgeville")
check(button.hidden == false and button.label == "Mark as discovered", "button offers to mark visited")

-- Mark it visited.
button.hooks.ONBUTTONPRESSED(button)
check(string.find(summary.content, "1 discovered", 1, true) ~= nil, "summary counts the visit")
check(button.label == "Mark as not discovered", "button now offers to undo")
check(database["visited:CloudGiraffe"] and database["visited:CloudGiraffe"].DKR == true,
    "visit saved under the character's name")
local selectedLabel = nil
for _, entry in ipairs(ringList.entries) do
    if entry.id == ringList.selected then selectedLabel = entry.label end
end
check(selectedLabel ~= nil and string.find(selectedLabel, "DKR", 1, true) == 1,
    "selection survives the list refresh (got " .. tostring(selectedLabel) .. ")")

-- Filter to rings not visited yet.
search.content = ""
search.hooks.ONCONTENTCHANGED(search, "CONTENT_CHANGE", "")
filterList:SetEntrySelected(2, true)
filterList.hooks.ONSELECTIONCHANGED(filterList, 2, 1)
check(#ringList.entries == 55, "not-visited filter hides Edgeville (got " .. #ringList.entries .. ")")

-- Open the (fake) travel log: its rings become discovered automatically.
require("src/sources/log_reader").SetInterfaceIds({ 999 })
travelLogOpen = true
for _ = 1, 3 do fire("ServerLogic", nil) end
check(database["detected:CloudGiraffe"] and database["detected:CloudGiraffe"].AIQ == true
    and database["detected:CloudGiraffe"].CKS == true, "rings in the travel log are detected and saved")
check(database["detected:CloudGiraffe"].AIP == nil, "Zanaris hub text does not mark AIP")
check(#ringList.entries == 53, "not-discovered filter now also hides AIQ and CKS (got "
    .. #ringList.entries .. ")")

-- The game's travel-log variables arrive: BJQ and DLR become discovered.
gameVarsReady = true
for _ = 1, 10 do fire("ServerLogic", nil) end
check(#ringList.entries == 51, "travel-log variables hide BJQ and DLR too (got " .. #ringList.entries .. ")")
check(string.find(summary.content, "discovered", 1, true) ~= nil, "summary still shown")
local bjqShown = false
filterList:SetEntrySelected(1, true)
filterList.hooks.ONSELECTIONCHANGED(filterList, 1, 1)
for _, entry in ipairs(ringList.entries) do
    if string.find(entry.label, "BJQ", 1, true) == 1 then
        bjqShown = true
        check(string.find(entry.label, "discovered", 1, true) ~= nil, "BJQ tagged discovered")
        check(string.find(entry.label, "needs repair", 1, true) == nil, "used ring no longer says it needs repair")
    end
end
check(bjqShown, "BJQ listed under All rings")

print(failures == 0 and "mock game test passed" or (failures .. " check(s) failed"))
if failures > 0 then
    os.exit(1)
end
