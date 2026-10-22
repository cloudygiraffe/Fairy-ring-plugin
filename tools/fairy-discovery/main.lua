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
--   3. Watches for any open game window whose text contains ring codes, and
--      prints its interface ID plus a sample of its text. Open the fairy ring
--      dial screen and the travel log: their IDs go into
--      fairy-ring-codes/src/sources/log_reader.lua.

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
-- 3: find the fairy ring windows
--------------------------------------------------------------------------------

local MAX_INTERFACE_ID = 3000      -- how many interface IDs to check
local INTERFACE_CHECK_TICKS = 5    -- check every 5 server ticks (~3 s)
local MAX_COMPONENTS = 3000
local reportedInterfaces = {}      -- interfaceId -> true once printed

-- Collects up to `limit` non-empty text strings from a component tree.
local function collectText(component, out, budget, limit)
    if budget.remaining <= 0 or #out >= limit then return end
    budget.remaining = budget.remaining - 1
    local ok, content = pcall(function() return component.content end)
    if ok and type(content) == "string" and content ~= "" then
        table.insert(out, content)
    end
    local function child(c)
        collectText(c, out, budget, limit)
        return budget.remaining <= 0 or #out >= limit
    end
    pcall(function() component:IterateStaticComponents(child) end)
    pcall(function() component:IterateDynamicComponents(child) end)
end

-- Counts ring-code-looking tokens (e.g. "AIQ" or "A I Q") in a string.
local function countCodes(text)
    local count = 0
    local upper = " " .. string.upper(string.gsub(text, "<[^>]*>", " ")) .. " "
    for _ in string.gmatch(upper, "%f[%w][A-D]%s?[I-L]%s?[P-S]%f[%W]") do
        count = count + 1
    end
    return count
end

local function inspectInterface(interfaceId, interface)
    local texts, budget = {}, { remaining = MAX_COMPONENTS }
    local function top(component)
        collectText(component, texts, budget, 200)
        return budget.remaining <= 0
    end
    local listed = pcall(function() interface:IterateStaticComponents(top) end)
    if not listed then
        for staticId = 0, 400 do
            local ok, component = pcall(function()
                return ui.Interfaces:GetComponent(interfaceId, staticId)
            end)
            if ok and component ~= nil then top(component) end
        end
    end
    local codes = 0
    for _, text in ipairs(texts) do codes = codes + countCodes(text) end
    if codes >= 2 then
        reportedInterfaces[interfaceId] = true
        say(string.format("FAIRY WINDOW? interface=%d codes=%d listedChildren=%s texts=%d",
            interfaceId, codes, tostring(listed), #texts))
        for index = 1, math.min(#texts, 25) do
            say("   text: " .. texts[index])
        end
    end
end

-- Also list any interface names in id.Interface that mention fairies, in
-- case the game exposes them by name.
pcall(function()
    for name, value in pairs(id.Interface) do
        if string.find(string.upper(tostring(name)), "FAIRY", 1, true) then
            say("id.Interface name:", name, "=", tostring(value))
        end
    end
end)

local interfaceTicks = 0
local lastInspected = {} -- interfaceId -> interfaceTicks when last inspected
local RECHECK_TICKS = 50 -- re-read an open, non-fairy window every ~30 s at most
Event.ServerLogic.Subscribe("fairyDiscoveryWindows", function()
    interfaceTicks = interfaceTicks + 1
    if interfaceTicks % INTERFACE_CHECK_TICKS ~= 0 then return end
    for interfaceId = 0, MAX_INTERFACE_ID do
        local recentlyChecked = lastInspected[interfaceId] ~= nil
            and interfaceTicks - lastInspected[interfaceId] < RECHECK_TICKS
        if not reportedInterfaces[interfaceId] and not recentlyChecked then
            local ok, interface = pcall(function()
                return ui.Interfaces:GetInterface(interfaceId)
            end)
            if ok and interface ~= nil then
                lastInspected[interfaceId] = interfaceTicks
                inspectInterface(interfaceId, interface)
            else
                lastInspected[interfaceId] = nil -- closed: inspect as soon as it reopens
            end
        end
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
