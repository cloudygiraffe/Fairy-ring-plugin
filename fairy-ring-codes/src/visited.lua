-- visited.lua
-- Keeps track of which rings the player has visited, per character.
--
-- Two kinds of information are combined:
--   * marks the player sets in the panel ("Mark as visited")
--   * rings the game itself reports as visited, once the discovery tool has
--     found the variable for it (see sources/game_source.lua)
--
-- PersistentDB is shared by every character on this computer, so each
-- character's marks are saved under its own key.

local Visited = {}

local KEY_PREFIX = "visited:"

local characterKey = nil -- e.g. "visited:CloudGiraffe"
local manual = {}        -- codes the player marked: { AIQ = true }
local fromGame = {}      -- codes the game reported: { AIQ = true }

-- Sets which character's marks are in use and loads them. `name` may be nil
-- before login, in which case marks are kept in memory only.
function Visited.UseCharacter(name)
    if type(name) ~= "string" or name == "" then
        characterKey = nil
        manual = {}
        return
    end
    characterKey = KEY_PREFIX .. name
    local ok, saved = pcall(function()
        return PersistentDB:GetStructuredData(characterKey)
    end)
    if ok and type(saved) == "table" then
        manual = saved
    else
        manual = {}
    end
end

local function save()
    if characterKey == nil then
        return
    end
    pcall(function()
        return PersistentDB:SetStructuredData(characterKey, manual)
    end)
end

-- Marks or unmarks a ring by hand.
function Visited.SetManual(code, isVisited)
    if isVisited then
        manual[code] = true
    else
        manual[code] = nil
    end
    save()
end

-- Replaces the set of rings the game reports as visited.
function Visited.SetFromGame(codes)
    fromGame = codes or {}
end

-- True if either source says the ring was visited.
function Visited.Is(code)
    return manual[code] == true or fromGame[code] == true
end

-- True if the game (not just a manual mark) reports the ring as visited.
function Visited.IsFromGame(code)
    return fromGame[code] == true
end

-- A plain set of all visited codes, for filtering.
function Visited.AsSet()
    local result = {}
    for code in pairs(manual) do result[code] = true end
    for code in pairs(fromGame) do result[code] = true end
    return result
end

-- Test helper.
function Visited.Reset()
    characterKey = nil
    manual = {}
    fromGame = {}
end

return Visited
