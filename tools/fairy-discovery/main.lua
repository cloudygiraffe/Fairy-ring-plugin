-- Fairy Discovery (developer tool, never meant for the Plugin Hub)
--
-- Run this on the plugin beta world to find the game variables that record
-- which fairy rings you have visited. Everything is printed to the client
-- console (ALT + the key under Esc). Copy the console output into an issue.
--
-- What it does:
--   1. Lists every VarPlayer / VarClient whose name looks fairy-ring related,
--      with its current value.
--   2. When you use a fairy ring (right-click options such as Configure,
--      Zanaris or Last-destination), logs EVERY variable that changes in the
--      next 30 seconds. Teleport to a ring you have never visited; the
--      "visited" flag should be one of the few variables that change.

local KEYWORDS = { "FAIRY", "ZANARIS", "TRAVEL_LOG", "TRAVELLOG", "DIAL", "FAIRYRING" }
local RING_VERBS = { "configure", "zanaris", "last-destination", "last destination", "use" }
local DOMAINS = { "VarPlayer", "VarClient" }
local IDS_PER_TICK = 600
local MAX_CONSECUTIVE_MISSES = 5000
local HARD_ID_LIMIT = 150000
local CAPTURE_SECONDS = 30

local function say(...)
    print("[Fairy discovery]", ...)
end

--------------------------------------------------------------------------------
-- 1: scan variable names
--------------------------------------------------------------------------------

local matches = {} -- configName -> true

local function nameMatches(name)
    local upper = string.upper(name or "")
    for _, keyword in ipairs(KEYWORDS) do
        if string.find(upper, keyword, 1, true) then
            return true
        end
    end
    return false
end

local function describe(variable)
    local ok, value = pcall(function() return variable.value end)
    return string.format("id=%s name=%s value=%s varbit=%s",
        tostring(variable.id), tostring(variable.configName),
        ok and tostring(value) or "?", tostring(variable.isVarBit))
end

local function lookup(domain, variableId)
    local ok, variable = pcall(function() return var[domain].FromID(variableId) end)
    if ok then return variable end
    return nil
end

-- Each job walks IDs in one direction: up from 0, or down from -1 for
-- varbits (whose IDs are negative in the docs' examples).
local jobs = {}
for _, domain in ipairs(DOMAINS) do
    table.insert(jobs, { domain = domain, nextId = 0, step = 1, misses = 0, found = 0 })
    table.insert(jobs, { domain = domain, nextId = -1, step = -1, misses = 0, found = 0 })
end

local function scanStep()
    local job = jobs[1]
    if job == nil then return false end
    for _ = 1, IDS_PER_TICK do
        local variable = lookup(job.domain, job.nextId)
        if variable ~= nil then
            job.misses = 0
            job.found = job.found + 1
            if nameMatches(variable.configName) then
                matches[variable.configName] = true
                say("MATCH", job.domain, describe(variable))
            end
        else
            job.misses = job.misses + 1
        end
        job.nextId = job.nextId + job.step
        if job.misses >= MAX_CONSECUTIVE_MISSES or math.abs(job.nextId) > HARD_ID_LIMIT then
            say(string.format("finished %s %s: %d variables found",
                job.domain, job.step > 0 and "(normal)" or "(varbits)", job.found))
            table.remove(jobs, 1)
            if #jobs == 0 then
                say("Scan complete. Now use a fairy ring you have never visited.")
            end
            return true
        end
    end
    return true
end

--------------------------------------------------------------------------------
-- 2: capture variable changes after using a fairy ring
--------------------------------------------------------------------------------

local latestTick = 0
local captureUntilTick = nil

Event.Logic.Subscribe("fairyDiscoveryTick", function(event)
    latestTick = event.logicTick
end)

local function isRingVerb(verbText)
    local verb = string.lower(verbText or "")
    for _, ringVerb in ipairs(RING_VERBS) do
        if verb == ringVerb then
            return true
        end
    end
    return false
end

Event.MiniMenuEntrySelected.Subscribe("fairyDiscoveryMenu", function(event)
    -- subjectText is the entry's target as shown in the menu (e.g. "Fairy ring"),
    -- possibly with colour tags, which are stripped.
    local ok, verb, target = pcall(function()
        local entry = event.entry
        local subject = string.gsub(entry.subjectText or "", "<[^>]*>", "")
        return entry.verbText, subject
    end)
    if not ok then
        return
    end
    -- Only start capturing for fairy-ring-looking interactions.
    if isRingVerb(verb) and (target == "" or string.find(string.lower(target), "fairy", 1, true)) then
        captureUntilTick = latestTick + CAPTURE_SECONDS * 50
        say("Capturing variable changes for " .. CAPTURE_SECONDS .. " s after: "
            .. tostring(verb) .. " " .. tostring(target))
    end
end)

Event.VarTransmit.Subscribe("fairyDiscoveryVars", function(event)
    local name = event.var and event.var.configName or "?"
    local capturing = captureUntilTick ~= nil and latestTick <= captureUntilTick
    if matches[name] or capturing then
        say(matches[name] and "CHANGE (matched)" or "CHANGE (after ring use)", name,
            tostring(event.oldValue) .. " -> " .. tostring(event.newValue))
    end
end)

--------------------------------------------------------------------------------
-- Drive the scan from the server tick
--------------------------------------------------------------------------------

say("Scanning variable names. This takes a minute or two...")
local scanFinished = false
Event.ServerLogic.Subscribe("fairyDiscoveryScan", function()
    if not scanFinished then
        scanFinished = not scanStep()
    end
end)
