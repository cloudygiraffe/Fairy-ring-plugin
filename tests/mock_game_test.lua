-- End-to-end test of main.lua against a fake version of the game's plugin API.
--
-- Run from the repository root:
--     lua tests/mock_game_test.lua
--
-- The fakes only implement what the plugin uses, with the names documented at
-- developer.runescape.com. Reading an unknown API member, or setting an
-- undocumented component property, raises an error.

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
            table.insert(state.entries, { label = label, id = entryId })
            return true
        end
        function methods.Clear(_) state.entries = {} state.selected = nil end
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

ui = strict("ui", {
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

var = strict("var", {})

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

check(#filterList.entries == 5, "filter dropdown has 5 choices")
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
check(button.hidden == false and button.label == "Mark as visited", "button offers to mark visited")

-- Mark it visited.
button.hooks.ONBUTTONPRESSED(button)
check(string.find(summary.content, "1 visited", 1, true) ~= nil, "summary counts the visit")
check(button.label == "Mark as not visited", "button now offers to undo")
check(database["visited:CloudGiraffe"] and database["visited:CloudGiraffe"].DKR == true,
    "visit saved under the character's name")
check(ringList.selected == edgeville.id, "selection survives the list refresh")

-- Filter to rings not visited yet.
search.content = ""
search.hooks.ONCONTENTCHANGED(search, "CONTENT_CHANGE", "")
filterList:SetEntrySelected(2, true)
filterList.hooks.ONSELECTIONCHANGED(filterList, 2, 1)
check(#ringList.entries == 55, "not-visited filter hides Edgeville (got " .. #ringList.entries .. ")")

print(failures == 0 and "mock game test passed" or (failures .. " check(s) failed"))
if failures > 0 then
    os.exit(1)
end
