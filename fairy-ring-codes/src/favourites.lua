-- favourites.lua
-- Suggested fairy ring favourites, for clue scrolls and for general travel.
--
-- The game lets you number your favourite rings (and pick them with the
-- number keys). The plugin cannot set those for you, since that would be
-- acting on your behalf, so it suggests which ones are worth setting.
--
-- Each suggestion: { code = "DKR", reason = "one line on why" }, best first.
-- Sources are listed at the end of the file.

local Favourites = {}

Favourites.LISTS = {
    clues = {
    },
    travel = {
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
