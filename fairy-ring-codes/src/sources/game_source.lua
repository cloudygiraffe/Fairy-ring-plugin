-- sources/game_source.lua
-- Reads which fairy rings the game says you have visited.
--
-- STATUS: not wired up yet. The game clearly tracks this (since February
-- 2021 the dial screen only names destinations you have visited, and the
-- travel log only lists those), but the variable names are not documented.
-- Finding them is the job of tools/fairy-discovery (see docs/TESTING.md).
--
-- Until then, players can mark rings as visited by hand in the panel.
--
-- Once the discovery tool has identified the variable(s), add them to
-- KNOWN_VARIABLES. Each entry says where the variable lives and how to turn
-- its value into a set of visited codes. Nothing else needs to change.

local GameSource = {}

-- Example of what an entry might look like if, say, one bit per ring is
-- stored in a variable:
--
--   {
--       domain = "VarPlayer",
--       name = "FAIRY_RING_VISITED_1",   -- configName from the discovery tool
--       decode = function(value)
--           -- return { AIQ = true, DKR = true, ... }
--       end,
--   },
local KNOWN_VARIABLES = {
}

local function readVariable(entry)
    local ok, value = pcall(function()
        return var[entry.domain][entry.name].value
    end)
    if ok then
        return value
    end
    return nil
end

-- True once at least one variable has been configured.
function GameSource.IsConfigured()
    return #KNOWN_VARIABLES > 0
end

-- Returns the set of visited codes the game reports, or nil if unknown.
function GameSource.ReadVisited()
    if not GameSource.IsConfigured() then
        return nil
    end
    local visited = {}
    local foundAny = false
    for _, entry in ipairs(KNOWN_VARIABLES) do
        local value = readVariable(entry)
        if value ~= nil then
            local ok, codes = pcall(entry.decode, value)
            if ok and type(codes) == "table" then
                foundAny = true
                for code in pairs(codes) do
                    visited[code] = true
                end
            end
        end
    end
    if foundAny then
        return visited
    end
    return nil
end

-- True if a VarTransmit event concerns one of our variables.
function GameSource.IsOurVariable(event)
    if event == nil or event.var == nil then
        return false
    end
    local ok, name = pcall(function() return event.var.configName end)
    if not ok then
        return false
    end
    for _, entry in ipairs(KNOWN_VARIABLES) do
        if entry.name == name then
            return true
        end
    end
    return false
end

return GameSource
