-- sources/log_reader.lua
-- BACKUP source: learns which rings you have discovered by reading the text
-- of the game's own fairy ring windows while they are open. The primary
-- source is sources/game_source.lua (the travel-log variables), which needs
-- no open window; this reader only matters if those variables ever stop
-- being readable.
--
-- The game's travel log only lists rings you have already visited, and the
-- dial screen only names a destination once you have been there. So any ring
-- code or place name that appears in those windows has been discovered.
-- Reading on-screen text is read-only; the plugin never clicks, scrolls or
-- changes anything in the game's windows.
--
-- How it works:
--   * Every few server ticks, check whether one of the fairy ring windows
--     (KNOWN_INTERFACE_IDS) is loaded.
--   * If so, walk every component in it and read any text.
--   * Pull out ring codes ("AIQ" or "A I Q") and known place names.
--
-- If the game only builds the rows you can see, scrolling through the log
-- lets the plugin read the rest, because it re-reads while the window is open.
--
-- STATUS: inactive until KNOWN_INTERFACE_IDS is filled in. The window IDs are
-- not documented; tools/fairy-discovery prints them ("FAIRY WINDOW?") on the
-- beta world. ExtractCodes() works already and is unit tested, and the mock
-- game test exercises Read() against a fake travel log.

local Rings = require("src/rings")

local LogReader = {}

-- Interface IDs of the fairy ring dial screen and travel log, as reported by
-- tools/fairy-discovery. Example: { 734, 735 }
local KNOWN_INTERFACE_IDS = {
}

-- Safety limit on how many components one read may visit.
local MAX_COMPONENTS_PER_READ = 4000

-- If a window can't list its children directly, try fixed component numbers
-- 0 .. this limit instead.
local MAX_STATIC_ID = 400

-- Lower-case place name -> code, for matching text that shows only the name.
-- Zanaris (AIP) is left out: the fairy ring screens mention Zanaris as the
-- hub, which would mark it discovered when it isn't.
local codeByPlace = {}
for _, ring in ipairs(Rings.LIST) do
    if ring.code ~= "AIP" then
        codeByPlace[string.lower(ring.location)] = ring.code
    end
end

-- Finds every ring the text mentions, by code or by place name, and adds it
-- to `found` (a set of codes). Pure function: unit tested without the game.
--   text  : any string (colour tags are ignored); non-strings are skipped
--   found : set to add to, e.g. {}; returned for convenience
function LogReader.ExtractCodes(text, found)
    if type(text) ~= "string" or text == "" then
        return found
    end
    local plain = string.gsub(text, "<[^>]*>", " ") -- drop colour and other tags

    -- Codes: three letters from the three dials (A-D, I-L, P-S), possibly
    -- spaced out ("A I Q"), standing on their own.
    local upper = string.upper(plain)
    for first, second, third in string.gmatch(" " .. upper .. " ",
        "%f[%w]([A-D])%s?([I-L])%s?([P-S])%f[%W]") do
        local code = first .. second .. third
        if Rings.Get(code) then
            found[code] = true
        end
    end

    -- Place names, for rows that show only the destination.
    local lower = string.lower(plain)
    for place, code in pairs(codeByPlace) do
        if string.find(lower, place, 1, true) then
            found[code] = true
        end
    end
    return found
end

-- Reads text from a component, or "" if it has none or cannot be read.
local function readText(component)
    local ok, content = pcall(function() return component.content end)
    if ok and type(content) == "string" then
        return content
    end
    return ""
end

-- Visits a component and all its children, calling visit(component) on each.
-- `budget.remaining` caps the total number of components visited, so a huge
-- or cyclic tree can't stall the game.
local function walk(component, visit, budget)
    if budget.remaining <= 0 then
        return
    end
    budget.remaining = budget.remaining - 1
    visit(component)
    local function child(childComponent)
        walk(childComponent, visit, budget)
        return budget.remaining <= 0 -- returning true stops the iteration
    end
    pcall(function() component:IterateStaticComponents(child) end)
    pcall(function() component:IterateDynamicComponents(child) end)
end

-- Replaces the window IDs. Used by the tests; the plugin itself uses the
-- list above.
function LogReader.SetInterfaceIds(ids)
    KNOWN_INTERFACE_IDS = ids
end

-- True once at least one window ID has been configured.
function LogReader.IsConfigured()
    return #KNOWN_INTERFACE_IDS > 0
end

-- Reads every open fairy ring window. Returns a set of discovered codes, or
-- nil if no fairy ring window is open.
function LogReader.Read()
    local found = nil
    for _, interfaceId in ipairs(KNOWN_INTERFACE_IDS) do
        local okInterface, interface = pcall(function()
            return ui.Interfaces:GetInterface(interfaceId)
        end)
        if okInterface and interface ~= nil then
            found = found or {}
            local budget = { remaining = MAX_COMPONENTS_PER_READ }
            local function visitTopLevel(component)
                walk(component, function(each)
                    LogReader.ExtractCodes(readText(each), found)
                end, budget)
                return budget.remaining <= 0
            end
            -- The docs don't say whether an interface can list its components,
            -- so try that first and fall back to asking for each fixed
            -- component number (documented: ui.Interfaces:GetComponent).
            local listed = pcall(function()
                interface:IterateStaticComponents(visitTopLevel)
            end)
            if not listed then
                for staticId = 0, MAX_STATIC_ID do
                    local okComponent, component = pcall(function()
                        return ui.Interfaces:GetComponent(interfaceId, staticId)
                    end)
                    if okComponent and component ~= nil and visitTopLevel(component) then
                        break
                    end
                end
            end
        end
    end
    return found
end

return LogReader
