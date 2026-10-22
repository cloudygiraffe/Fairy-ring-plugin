-- favourites.lua
-- Suggested fairy ring favourites, for clue scrolls and for general travel.
--
-- The game lets you number your favourite rings (and pick them with the
-- number keys). The plugin cannot set those for you, since that would be
-- acting on your behalf, so it suggests which ones are worth setting.
--
-- Each suggestion: { code = "DKR", reason = "one line on why" }, best first.
-- The game's "Zanaris" right-click option (September 21st, 2026) makes AIP a
-- waste of a favourite slot, so it is never suggested.
--
-- Sources: runescape.wiki Treasure Trails guides (scans, coordinates, emotes,
-- maps), the elite and master scan pages, the Fairy ring page, and RuneHQ's
-- scan and coordinate guides, checked October 22nd, 2026. The travel list is
-- a judgement call from what each ring is near; suggestions welcome.

local Favourites = {}

-- Elite clues are only scan and compass steps, and master clues lean on
-- scans too, so the clue list favours scan areas with no lodestone, where the
-- Wiki describes dig spots from the ring itself. Reasons that are inferred
-- rather than taken from a guide say "likely".
Favourites.LISTS = {
    clues = {
        { code = "AKQ", reason = "Piscatoris Hunter area elite scan; no lodestone nearby" },
        { code = "ALQ", reason = "Haunted Woods elite scan, plus a hard emote step" },
        { code = "CJS", reason = "Kharazi Jungle elite scan and a hard coordinate" },
        { code = "DLQ", reason = "East Kharidian Desert elite scan" },
        { code = "AJR", reason = "Fremennik Slayer Dungeon elite scan and a medium coordinate" },
        { code = "BJS", reason = "Lost Grove master scan (likely the closest ring)" },
        { code = "CKR", reason = "Several medium and hard Karamja coordinates" },
        { code = "DIP", reason = "Mos Le'Harmless elite scan (likely; needs the bridges repaired)" },
    },
    travel = {
        { code = "DKQ", reason = "Glacor Cave: glacors and the Glacor cavern mine" },
        { code = "CKR", reason = "Karamja: nature altar, Hunter area, karambwanji, Shilo Village" },
        { code = "BIP", reason = "Polypore Dungeon, Mage Training Arena, brilliant wisps" },
        { code = "AKQ", reason = "Phoenix Lair, falconry, Piscatoris fishing colony" },
        { code = "BJQ", reason = "Kuradal's Dungeon for Slayer, Baxtorian Falls" },
        { code = "DIQ", reason = "Fenmoor in Havenhythe: fletching totems, Globin Village" },
        { code = "DLS", reason = "Myreque hideout: near Barrows, Mort'ton and Canifis" },
        { code = "ALR", reason = "The Abyss: abyssal demons and other Slayer monsters" },
    },
}

-- Returns the reasons a ring is suggested, e.g.
-- { { list = "clues", rank = 2, reason = "..." } }, or an empty table.
function Favourites.For(code)
    local result = {}
    for listName, suggestions in pairs(Favourites.LISTS) do
        for rank, suggestion in ipairs(suggestions) do
            if suggestion.code == code then
                table.insert(result, { list = listName, rank = rank, reason = suggestion.reason })
            end
        end
    end
    table.sort(result, function(a, b) return a.list < b.list end)
    return result
end

return Favourites
