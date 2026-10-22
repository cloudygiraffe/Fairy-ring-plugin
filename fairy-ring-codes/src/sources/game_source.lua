-- sources/game_source.lua
-- Reads which fairy rings are in your travel log, straight from the game's
-- variables. No permissions and no open windows needed.
--
-- The client's own variable list (console command `pan VarPlayer`, October
-- 22nd, 2026 beta client) has one bit per code:
--
--   FAIRYRINGS_LOG_AIP  varbit -12080  (VarPlayer 2482, bit 0)
--   FAIRYRINGS_LOG_AIQ  varbit -12081  (VarPlayer 2482, bit 1)
--   ...
--   FAIRYRINGS_LOG_BLS  varbit -12111  (VarPlayer 2482, bit 31)
--   FAIRYRINGS_LOG_CIP  varbit -12112  (VarPlayer 2483, bit 0)
--   ...
--   FAIRYRINGS_LOG_DLS  varbit -12143  (VarPlayer 2483, bit 31)
--
-- i.e. codes in dial order (A-D, then I-L, then P-S), 64 in all. The varbits
-- are read first; if the client won't hand them out, the two whole VarPlayers
-- are read and split into bits instead.

local GameSource = {}

local FIRST = { "A", "B", "C", "D" }
local SECOND = { "I", "J", "K", "L" }
local THIRD = { "P", "Q", "R", "S" }

local FIRST_VARBIT = -12080
local LOG_VARPS = { 2482, 2483 }

-- All 64 codes in the order the game stores them.
GameSource.CODES = {}
for _, a in ipairs(FIRST) do
    for _, b in ipairs(SECOND) do
        for _, c in ipairs(THIRD) do
            table.insert(GameSource.CODES, a .. b .. c)
        end
    end
end

-- Varbit ID for a code's travel-log bit (AIP -> -12080, DLS -> -12143).
function GameSource.VarbitFor(code)
    for index, candidate in ipairs(GameSource.CODES) do
        if candidate == code then
            return FIRST_VARBIT - (index - 1)
        end
    end
    return nil
end

local function readVarPlayer(variableId)
    local ok, value = pcall(function()
        return var.VarPlayer.FromID(variableId).value
    end)
    if ok and type(value) == "number" then
        return value
    end
    return nil
end

-- Turns a 32-bit value (possibly negative if the top bit is set) into a list
-- of 32 booleans, without relying on bitwise operators.
function GameSource.Bits(value)
    if value < 0 then
        value = value + 4294967296
    end
    local bits = {}
    for bit = 1, 32 do
        bits[bit] = value % 2 == 1
        value = math.floor(value / 2)
    end
    return bits
end

local function readFromVarbits()
    local visited, readAny = {}, false
    for index, code in ipairs(GameSource.CODES) do
        local value = readVarPlayer(FIRST_VARBIT - (index - 1))
        if value ~= nil then
            readAny = true
            if value ~= 0 then
                visited[code] = true
            end
        end
    end
    if readAny then
        return visited
    end
    return nil
end

local function readFromVarps()
    local visited = {}
    for half, variableId in ipairs(LOG_VARPS) do
        local value = readVarPlayer(variableId)
        if value == nil then
            return nil
        end
        local bits = GameSource.Bits(value)
        for bit = 1, 32 do
            if bits[bit] then
                visited[GameSource.CODES[(half - 1) * 32 + bit]] = true
            end
        end
    end
    return visited
end

-- Kept for main.lua: the source is always configured now.
function GameSource.IsConfigured()
    return true
end

-- Returns the set of codes in your travel log, e.g. { AIQ = true, ... }, or
-- nil if the game's variables can't be read (for example before login).
function GameSource.ReadVisited()
    return readFromVarbits() or readFromVarps()
end

-- True if a VarTransmit event concerns the travel log.
function GameSource.IsOurVariable(event)
    local ok, name = pcall(function() return event.var.configName end)
    if not ok or type(name) ~= "string" then
        return false
    end
    return string.sub(name, 1, 15) == "FAIRYRINGS_LOG_"
end

return GameSource
