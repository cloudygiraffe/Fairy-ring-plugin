-- filter.lua
-- Decides which rings to show for the current search text and filter.
-- Pure logic with no game calls, so it is fully unit tested.

local Dates = require("src/dates")
local Favourites = require("src/favourites")

local Filter = {}

-- Filter choices, in the order shown in the dropdown. `id` is what the
-- dropdown reports; `label` is what the player sees.
Filter.MODES = {
    { id = 1, key = "all",         label = "All rings" },
    { id = 2, key = "notDiscovered", label = "Not discovered yet" },
    { id = 3, key = "clues",       label = "Suggested favourites: clues" },
    { id = 4, key = "travel",      label = "Suggested favourites: travel" },
    { id = 5, key = "needsSetup",  label = "Need repairing or building" },
    { id = 6, key = "recent",      label = "Added recently" },
    { id = 7, key = "requirement", label = "Have a quest or skill requirement" },
}

-- Rings added on or after this date count as "recent". Move it forward when
-- the data file gets a new batch of rings.
Filter.RECENT_SINCE = { 2026, 1, 1 }

function Filter.ModeByID(modeId)
    for _, mode in ipairs(Filter.MODES) do
        if mode.id == modeId then
            return mode
        end
    end
    return Filter.MODES[1]
end

-- Normalises search text: lower case, no surrounding spaces.
local function normalise(text)
    text = string.lower(text or "")
    return (string.gsub(text, "^%s*(.-)%s*$", "%1"))
end

-- True if the search text matches the ring's code or location.
-- Codes match with or without spaces ("a i q" finds AIQ); places match on any
-- part of the name ("canifis" finds both Canifis rings).
function Filter.MatchesSearch(ring, searchText)
    local query = normalise(searchText)
    if query == "" then
        return true
    end
    local compactQuery = string.gsub(query, "%s", "")
    if string.find(string.lower(ring.code), compactQuery, 1, true) == 1 then
        return true
    end
    return string.find(string.lower(ring.location), query, 1, true) ~= nil
end

-- True if the ring belongs in the chosen filter.
--   modeKey : one of the `key` values in Filter.MODES
--   visited : set of discovered codes, e.g. { AIQ = true }
function Filter.MatchesMode(ring, modeKey, visited)
    if modeKey == "notDiscovered" then
        return not visited[ring.code]
    elseif modeKey == "needsSetup" then
        return ring.setup ~= nil
    elseif modeKey == "recent" then
        return Dates.IsOnOrAfter(ring.added, Filter.RECENT_SINCE)
    elseif modeKey == "requirement" then
        return ring.requirement ~= nil
    end
    return true
end

-- Returns the multi-code destinations to show. They only appear under
-- "All rings", matched by place name or any of their codes.
function Filter.ApplySequences(sequences, searchText, modeKey)
    local result = {}
    if modeKey ~= "all" then
        return result
    end
    local query = normalise(searchText)
    local compactQuery = string.gsub(query, "%s", "")
    for _, sequence in ipairs(sequences) do
        local matches = query == ""
            or string.find(string.lower(sequence.location), query, 1, true) ~= nil
        if not matches then
            for _, code in ipairs(sequence.codes) do
                if string.find(string.lower(code), compactQuery, 1, true) == 1 then
                    matches = true
                end
            end
        end
        if matches then
            table.insert(result, sequence)
        end
    end
    return result
end

-- Returns the rings to show. Suggested-favourite filters keep the
-- suggestion order (best first); every other filter uses data-file order.
function Filter.Apply(rings, searchText, modeKey, visited)
    local suggestions = Favourites.LISTS[modeKey]
    if suggestions then
        local byCode = {}
        for _, ring in ipairs(rings) do byCode[ring.code] = ring end
        local ordered = {}
        for _, suggestion in ipairs(suggestions) do
            local ring = byCode[suggestion.code]
            if ring and Filter.MatchesSearch(ring, searchText) then
                table.insert(ordered, ring)
            end
        end
        return ordered
    end

    local result = {}
    for _, ring in ipairs(rings) do
        if Filter.MatchesMode(ring, modeKey, visited) and Filter.MatchesSearch(ring, searchText) then
            table.insert(result, ring)
        end
    end
    return result
end

return Filter
