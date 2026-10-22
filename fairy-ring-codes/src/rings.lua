-- rings.lua
-- Every RuneScape 3 fairy ring code, what it needs, and whether the ring must
-- be repaired or built before first use.
--
-- DATA SOURCE AND LICENCE
-- Compiled from the RuneScape Wiki's "Fairy ring" page and related pages
-- (runescape.wiki/w/Fairy_ring), October 22nd, 2026. Wiki content is licensed
-- CC BY-NC-SA 3.0, so this file is shared under the same licence with credit
-- to the RuneScape Wiki contributors. (The rest of the plugin is MIT.)
--
-- UPDATING
-- When Jagex adds a ring, add one entry below and bump DATA_VERSION. Nothing
-- else in the plugin needs to change.
--
-- Fields:
--   code        three letters, as dialled
--   location    the name the in-game travel log uses
--   area        "Mainland" or "Islands and realms" (for grouping)
--   requirement extra requirement beyond the base ones, or nil
--   setup       nil, or { kind = "repair" | "build" | "bridges", detail = "..." }
--               for rings that need work before the first teleport
--   added       { year, month, day } for rings added since the 2017 expansion,
--               or nil for long-standing rings
--   note        optional extra tip

local Rings = {}

Rings.DATA_VERSION = "2026-10-22"

-- Requirements that apply to every fairy ring.
Rings.BASE_REQUIREMENTS = {
    "Members",
    "Priest in Peril, Nature Spirit, Lost City and A Fairy Tale I complete",
    "A Fairy Tale II started",
    "Dramen or Lunar staff, until A Fairy Tale III is complete",
}

-- Shorthand for the most common repair.
local BITTERCAP_REPAIR = {
    kind = "repair",
    detail = "Repair with 5 bittercap mushrooms and a spade before first use",
}

Rings.LIST = {
    -- Mainland -----------------------------------------------------------------
    { code = "AIP", location = "Zanaris", area = "Mainland",
      note = "Only shows in the travel log after you teleport here from another ring",
      added = { 2021, 2, 8 } },
    { code = "AIQ", location = "Asgarnia: Mudskipper Point", area = "Mainland" },
    { code = "AJQ", location = "Dark cave south of Dorgesh-Kaan", area = "Mainland",
      requirement = "Death to the Dorgeshuun", note = "Bring a light source" },
    { code = "AJR", location = "Slayer cave south-east of Rellekka", area = "Mainland" },
    { code = "AKQ", location = "Piscatoris Hunter area", area = "Mainland" },
    { code = "AKS", location = "Feldip Hunter area", area = "Mainland" },
    { code = "ALP", location = "Feldip Hills, near Gu'Tanoth", area = "Mainland",
      requirement = "Partial completion of A Fairy Tale III" },
    { code = "ALQ", location = "Haunted Woods, east of Canifis", area = "Mainland",
      note = "Aggressive monsters nearby" },
    { code = "ALS", location = "McGrubor's Wood", area = "Mainland" },
    { code = "BIP", location = "Islands south-west of Mort Myre (Polypore Dungeon)", area = "Mainland" },
    { code = "BIQ", location = "Kharidian Desert, near the Kalphite hive", area = "Mainland" },
    { code = "BJP", location = "Fort Forinthry", area = "Mainland",
      requirement = "Fort Forinthry Grove built to tier 2",
      setup = { kind = "build", detail = "Appears once the Fort's Grove reaches tier 2" },
      added = { 2023, 6, 19 } },
    { code = "BJQ", location = "Ancient Cavern", area = "Mainland",
      requirement = "Most of Barbarian Training", setup = BITTERCAP_REPAIR },
    { code = "BJS", location = "The Lost Grove", area = "Mainland",
      setup = BITTERCAP_REPAIR, added = { 2017, 9, 25 } },
    { code = "BKP", location = "South of Castle Wars", area = "Mainland" },
    { code = "BKR", location = "Mort Myre, south of Canifis", area = "Mainland" },
    { code = "BKS", location = "Havenhythe: Shrine of Inanna", area = "Mainland",
      requirement = "Visions of Havenhythe", added = { 2026, 3, 23 } },
    { code = "BLP", location = "TzHaar area", area = "Mainland" },
    { code = "BLR", location = "Legends' Guild", area = "Mainland" },
    { code = "CIP", location = "Miscellania", area = "Mainland",
      requirement = "The Fremennik Trials" },
    { code = "CIQ", location = "North-west of Yanille", area = "Mainland" },
    { code = "CJR", location = "Sinclair Mansion (east)", area = "Mainland" },
    { code = "CJS", location = "Kharazi Jungle", area = "Mainland",
      requirement = "Legends' Quest started", setup = BITTERCAP_REPAIR,
      added = { 2017, 7, 10 } },
    { code = "CKQ", location = "Menaphos: Imperial District", area = "Mainland",
      added = { 2017, 6, 5 }, note = "Sources disagree on the exact 2017 release date" },
    { code = "CKR", location = "South of Tai Bwo Wannai", area = "Mainland" },
    { code = "CKS", location = "Canifis", area = "Mainland" },
    { code = "CLR", location = "Ape Atoll", area = "Mainland",
      requirement = "Partial completion of A Fairy Tale III",
      note = "Ninja monkey greegree needed to pass the hollow log" },
    { code = "CLS", location = "Jungle spiders island near Yanille", area = "Mainland" },
    { code = "DIP", location = "Mos Le'Harmless island", area = "Mainland",
      requirement = "Partial completion of A Fairy Tale III",
      setup = { kind = "bridges",
                detail = "Repair the bridges first: 8 planks, 16 nails and a hammer" } },
    { code = "DIQ", location = "Fenmoor, Havenhythe (east of Linbog Village)", area = "Mainland",
      requirement = "Partial completion of Heralds of Crimson; 79 Agility for the rotten log",
      setup = { kind = "repair",
                detail = "Repair with 5 bogwart mushrooms and a spade before first use" },
      added = { 2026, 9, 28 } },
    { code = "DIS", location = "Wizards' Tower", area = "Mainland" },
    { code = "DJP", location = "Tower of Life", area = "Mainland" },
    { code = "DJR", location = "Sinclair Mansion (west)", area = "Mainland" },
    { code = "DJS", location = "Prifddinas: Amlodd district", area = "Mainland",
      requirement = "Plague's End" },
    { code = "DKP", location = "South of Musa Point", area = "Mainland" },
    { code = "DKQ", location = "Glacor Cave", area = "Mainland",
      requirement = "Ritual of the Mahjarrat" },
    { code = "DKR", location = "Edgeville", area = "Mainland" },
    { code = "DKS", location = "Snowy Hunter area", area = "Mainland" },
    { code = "DLP", location = "Havenhythe: north of Amberfell", area = "Mainland",
      requirement = "Partial completion of Secrets of Amberfell", added = { 2026, 6, 1 } },
    { code = "DLQ", location = "North of Nardah", area = "Mainland" },
    { code = "DLR", location = "Poison Waste islands, south of Isafdar", area = "Mainland",
      note = "The other islands need partial completion of Plague's End" },
    { code = "DLS", location = "Myreque hideout under The Hollows", area = "Mainland",
      requirement = "In Search of the Myreque" },

    -- Islands, other realms and your house ----------------------------------
    { code = "AIR", location = "Islands south of Witchaven", area = "Islands and realms",
      note = "Mostly used for one Treasure Trail coordinate" },
    { code = "AIS", location = "Naragi homeworld", area = "Islands and realms",
      requirement = "The World Wakes" },
    { code = "AJS", location = "Penguin island near Miscellania", area = "Islands and realms" },
    { code = "AKP", location = "Your player-owned house", area = "Islands and realms",
      requirement = "85 Construction",
      setup = { kind = "build",
                detail = "Build a house fairy ring: 10 bittercap mushrooms and a fairy enchantment from Fairy Fixit" },
      added = { 2026, 7, 13 }, note = "Teleporting out cures poison" },
    { code = "ALR", location = "The Abyss", area = "Islands and realms",
      note = "Dangerous monsters" },
    { code = "BIR", location = "Sparse Plane", area = "Islands and realms",
      requirement = "Partial completion of A Fairy Tale III" },
    { code = "BIS", location = "Ardougne Zoo unicorns", area = "Islands and realms" },
    { code = "BJR", location = "Realm of the Fisher King", area = "Islands and realms",
      requirement = "Fisher Realm restored during Holy Grail" },
    { code = "BKQ", location = "Enchanted Valley", area = "Islands and realms" },
    { code = "BLQ", location = "Yu'biusk", area = "Islands and realms",
      requirement = "Land of the Goblins" },
    { code = "CIS", location = "ScapeRune (Evil Bob's island)", area = "Islands and realms" },
    { code = "CKP", location = "Cosmic Entity's plane", area = "Islands and realms" },
    { code = "CLP", location = "Island south of Draynor Village", area = "Islands and realms" },
    { code = "DIR", location = "Gorak Plane", area = "Islands and realms" },
}

-- Destinations reached by dialling several codes in a row.
Rings.SEQUENCES = {
    { codes = { "DIR", "AKS" }, location = "Kethsi",
      requirement = "Hidden; used during Ritual of the Mahjarrat" },
    { codes = { "AIR", "DLR", "DJQ", "AJS" }, location = "Fairy Queen's Hideout",
      requirement = "Nuff's certificate, until A Fairy Tale III is complete" },
    { codes = { "BIR", "DIP", "CLR", "ALP" }, location = "Ork's Rift",
      requirement = "During or after A Fairy Tale III" },
}

-- Codes that lead nowhere on their own (DJQ is only part of a sequence).
Rings.DEAD_CODES = { "AJP", "AKR", "BLS", "CIR", "CJP", "CJQ", "CLQ", "DJQ" }

-- Index by code for quick lookup.
local byCode = {}
for index, ring in ipairs(Rings.LIST) do
    ring.index = index
    byCode[ring.code] = ring
end

-- Returns the ring for a code ("aiq", "A I Q" and "AIQ" all work), or nil.
function Rings.Get(code)
    if type(code) ~= "string" then
        return nil
    end
    local cleaned = string.upper(string.gsub(code, "%s", ""))
    return byCode[cleaned]
end

-- Total number of single-code destinations.
function Rings.Count()
    return #Rings.LIST
end

return Rings
