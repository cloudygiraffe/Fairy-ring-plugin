-- visited.lua
-- Keeps track of which rings the player has discovered, per character.
--
-- Three kinds of information are combined:
--   * detected : rings seen in the game's own travel log or dial screen
--                (sources/log_reader.lua). Saved, since the game only shows
--                rings you have visited, so a ring seen once stays discovered.
--   * fromGame : rings a game variable reports as visited, once the discovery
--                tool has found that variable (sources/game_source.lua)
--   * manual   : rings the player marked by hand in the panel
--
-- PersistentDB is shared by every character on this computer, so each
-- character's data is saved under keys that include its name.

local Visited = {}

local MANUAL_PREFIX = "visited:"
local DETECTED_PREFIX = "detected:"

local characterName = nil
local manual = {}   -- { AIQ = true }
local detected = {} -- { AIQ = true }
local fromGame = {} -- { AIQ = true }

local function load(key)
    local ok, saved = pcall(function()
        return PersistentDB:GetStructuredData(key)
    end)
    if ok and type(saved) == "table" then
        return saved
    end
    return {}
end

local function save(key, set)
    if characterName == nil then
        return
    end
    pcall(function()
        return PersistentDB:SetStructuredData(key, set)
    end)
end

-- Sets which character's data is in use and loads it. `name` may be nil
-- before login, in which case nothing is saved.
function Visited.UseCharacter(name)
    fromGame = {}
    if type(name) ~= "string" or name == "" then
        characterName = nil
        manual, detected = {}, {}
        return
    end
    characterName = name
    manual = load(MANUAL_PREFIX .. name)
    detected = load(DETECTED_PREFIX .. name)
end

-- Marks or unmarks a ring by hand.
function Visited.SetManual(code, isVisited)
    if isVisited then
        manual[code] = true
    else
        manual[code] = nil
    end
    save(MANUAL_PREFIX .. characterName, manual)
end

-- Adds rings seen in the game's fairy ring windows. Returns the number of
-- rings that were not known before (so the caller knows whether to refresh).
function Visited.AddDetected(codes)
    local added = 0
    for code in pairs(codes or {}) do
        if not detected[code] then
            detected[code] = true
            added = added + 1
        end
    end
    if added > 0 and characterName then
        save(DETECTED_PREFIX .. characterName, detected)
    end
    return added
end

-- Replaces the set of rings a game variable reports as visited.
function Visited.SetFromGame(codes)
    fromGame = codes or {}
end

-- True if any source says the ring was discovered.
function Visited.Is(code)
    return manual[code] == true or detected[code] == true or fromGame[code] == true
end

-- True if the game (not just a manual mark) shows the ring as discovered.
function Visited.IsDetected(code)
    return detected[code] == true or fromGame[code] == true
end

-- A plain set of all discovered codes, for filtering.
function Visited.AsSet()
    local result = {}
    for code in pairs(manual) do result[code] = true end
    for code in pairs(detected) do result[code] = true end
    for code in pairs(fromGame) do result[code] = true end
    return result
end

-- Number of rings detected from the game (for the panel summary).
function Visited.DetectedCount()
    local count = 0
    for _ in pairs(detected) do count = count + 1 end
    for code in pairs(fromGame) do
        if not detected[code] then count = count + 1 end
    end
    return count
end

-- Test helper.
function Visited.Reset()
    characterName = nil
    manual, detected, fromGame = {}, {}, {}
end

return Visited
