-- Unit tests for the parts of the plugin that do not need the game client.
--
-- Run from the repository root with any Lua 5.1+ interpreter:
--     lua tests/run_tests.lua

package.path = "fairy-ring-codes/?.lua;" .. package.path

-- visited.lua saves through PersistentDB; give it an in-memory stand-in.
local fakeDatabase = {}
PersistentDB = {
    GetStructuredData = function(_, key) return fakeDatabase[key] end,
    SetStructuredData = function(_, key, value) fakeDatabase[key] = value return true end,
}

local Rings = require("src/rings")
local Dates = require("src/dates")
local Filter = require("src/filter")
local Display = require("src/display")
local Visited = require("src/visited")

local passed, failed = 0, 0

local function test(name, body)
    Visited.Reset()
    local ok, err = pcall(body)
    if ok then
        passed = passed + 1
    else
        failed = failed + 1
        print("FAIL: " .. name .. "\n      " .. tostring(err))
    end
end

local function eq(actual, expected, label)
    if actual ~= expected then
        error((label or "value") .. ": expected " .. tostring(expected)
            .. ", got " .. tostring(actual), 2)
    end
end

local function codesOf(rings)
    local codes = {}
    for _, ring in ipairs(rings) do
        table.insert(codes, ring.code)
    end
    return table.concat(codes, ",")
end

--------------------------------------------------------------------------------
-- Data integrity
--------------------------------------------------------------------------------

test("There are 56 single-code destinations, as the Wiki states", function()
    eq(Rings.Count(), 56)
end)

test("Working codes plus dead codes cover all 64 dial combinations exactly once", function()
    local seen = {}
    local function add(code)
        eq(seen[code], nil, "duplicate code " .. code)
        seen[code] = true
    end
    for _, ring in ipairs(Rings.LIST) do add(ring.code) end
    for _, code in ipairs(Rings.DEAD_CODES) do add(code) end
    local total = 0
    for first in string.gmatch("ABCD", ".") do
        for second in string.gmatch("IJKL", ".") do
            for third in string.gmatch("PQRS", ".") do
                eq(seen[first .. second .. third], true, "missing " .. first .. second .. third)
                total = total + 1
            end
        end
    end
    eq(total, 64)
end)

test("Every ring has a location and a known area", function()
    for _, ring in ipairs(Rings.LIST) do
        eq(type(ring.location), "string", ring.code .. " location")
        eq(ring.area == "Mainland" or ring.area == "Islands and realms", true, ring.code .. " area")
    end
end)

test("Every setup entry has a known kind and instructions", function()
    for _, ring in ipairs(Rings.LIST) do
        if ring.setup then
            local kind = ring.setup.kind
            eq(kind == "repair" or kind == "build" or kind == "bridges", true, ring.code .. " kind")
            eq(type(ring.setup.detail), "string", ring.code .. " detail")
        end
    end
end)

test("Sequence codes are all real codes", function()
    for _, sequence in ipairs(Rings.SEQUENCES) do
        for _, code in ipairs(sequence.codes) do
            local known = Rings.Get(code) ~= nil
            for _, dead in ipairs(Rings.DEAD_CODES) do
                if dead == code then known = true end
            end
            eq(known, true, sequence.location .. " uses " .. code)
        end
    end
end)

test("Codes are found regardless of case and spaces", function()
    eq(Rings.Get("dkr").location, "Edgeville")
    eq(Rings.Get("D K R").location, "Edgeville")
    eq(Rings.Get("ZZZ"), nil)
end)

--------------------------------------------------------------------------------
-- Dates
--------------------------------------------------------------------------------

test("Dates are written US-style with ordinals", function()
    eq(Dates.Format({ 2026, 9, 28 }), "September 28th, 2026")
    eq(Dates.Format({ 2026, 7, 1 }), "July 1st, 2026")
    eq(Dates.Format({ 2026, 3, 22 }), "March 22nd, 2026")
    eq(Dates.Format({ 2026, 3, 23 }), "March 23rd, 2026")
    eq(Dates.Format({ 2026, 3, 11 }), "March 11th, 2026")
end)

--------------------------------------------------------------------------------
-- Filtering
--------------------------------------------------------------------------------

test("Search by code prefix", function()
    eq(codesOf(Filter.Apply(Rings.LIST, "dk", "all", {})), "DKP,DKQ,DKR,DKS")
end)

test("Search by code with spaces", function()
    eq(codesOf(Filter.Apply(Rings.LIST, "c k s", "all", {})), "CKS")
end)

test("Search by place name", function()
    eq(codesOf(Filter.Apply(Rings.LIST, "havenhythe", "all", {})), "BKS,DIQ,DLP")
end)

test("Not visited hides visited rings", function()
    local all = #Filter.Apply(Rings.LIST, "", "notVisited", {})
    local fewer = #Filter.Apply(Rings.LIST, "", "notVisited", { AIQ = true, DKR = true })
    eq(all - fewer, 2)
end)

test("Need work lists the rings that must be repaired or built", function()
    eq(codesOf(Filter.Apply(Rings.LIST, "", "needsSetup", {})), "BJP,BJQ,BJS,CJS,DIP,DIQ,AKP")
end)

test("Added recently lists 2026 rings", function()
    eq(codesOf(Filter.Apply(Rings.LIST, "", "recent", {})), "BKS,DIQ,DLP,AKP")
end)

test("Multi-code destinations show under All rings only", function()
    eq(#Filter.ApplySequences(Rings.SEQUENCES, "", "all"), 3)
    eq(#Filter.ApplySequences(Rings.SEQUENCES, "", "needsSetup"), 0)
    eq(Filter.ApplySequences(Rings.SEQUENCES, "kethsi", "all")[1].location, "Kethsi")
end)

--------------------------------------------------------------------------------
-- Display
--------------------------------------------------------------------------------

test("List labels show setup, new and visited tags", function()
    eq(Display.ListLabel(Rings.Get("DIQ"), true, Filter.RECENT_SINCE),
        "DIQ  Fenmoor, Havenhythe (east of Linbog Village)  [needs repair, new, visited]")
    eq(Display.ListLabel(Rings.Get("DKR"), false, Filter.RECENT_SINCE), "DKR  Edgeville")
end)

test("Details include requirement, setup, date and visit state", function()
    local text = Display.Details(Rings.Get("AKP"), nil)
    eq(string.find(text, "85 Construction", 1, true) ~= nil, true, "requirement")
    eq(string.find(text, "Fairy Fixit", 1, true) ~= nil, true, "setup")
    eq(string.find(text, "July 13th, 2026", 1, true) ~= nil, true, "date")
    eq(string.find(text, "Not visited yet", 1, true) ~= nil, true, "visit state")
end)

test("Summary counts rings, visits and setup", function()
    eq(Display.Summary(Rings.LIST, { AIQ = true }), "56 rings | 1 visited | 7 need work before first use")
end)

--------------------------------------------------------------------------------
-- Visited tracking
--------------------------------------------------------------------------------

test("Manual marks are saved per character", function()
    Visited.UseCharacter("Alice")
    Visited.SetManual("AIQ", true)
    Visited.UseCharacter("Bob")
    eq(Visited.Is("AIQ"), false, "Bob")
    Visited.UseCharacter("Alice")
    eq(Visited.Is("AIQ"), true, "Alice")
end)

test("Game-reported visits combine with manual marks", function()
    Visited.UseCharacter("Alice")
    Visited.SetManual("AIQ", false)
    Visited.SetFromGame({ DKR = true })
    Visited.SetManual("CKS", true)
    local set = Visited.AsSet()
    eq(set.DKR, true)
    eq(set.CKS, true)
    eq(Visited.IsFromGame("CKS"), false)
end)

print(string.format("%d passed, %d failed", passed, failed))
if failed > 0 then
    os.exit(1)
end
