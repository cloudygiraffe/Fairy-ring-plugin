-- display.lua
-- Builds the text shown in the panel. Kept separate from the UI code so the
-- wording can be unit tested without the game. Uses RuneScape text markup:
-- "<br>" for a line break and "<col=RRGGBB>...</col>" for colour.

local Rings = require("src/rings")
local Dates = require("src/dates")
local Favourites = require("src/favourites")

local Display = {}

local HIGHLIGHT_COLOUR = "ffd24a" -- gold
local MUTED_COLOUR = "9a9a9a"     -- grey
local WARNING_COLOUR = "ff9f43"   -- orange, for rings that need work first

local function colour(text, hex)
    return "<col=" .. hex .. ">" .. text .. "</col>"
end

-- Short tag for rings that need work before the first teleport.
local SETUP_TAGS = {
    repair = "needs repair",
    build = "needs building",
    bridges = "needs bridges repaired",
}

-- One line in the ring list, e.g. "AIQ  Asgarnia: Mudskipper Point [discovered]".
-- List entries are plain text, so tags are written in brackets.
function Display.ListLabel(ring, isVisited, recentSince)
    local tags = {}
    -- A ring you've already used has obviously been repaired or built.
    if ring.setup and not isVisited then
        table.insert(tags, SETUP_TAGS[ring.setup.kind] or "needs setup")
    end
    if recentSince and Dates.IsOnOrAfter(ring.added, recentSince) then
        table.insert(tags, "new")
    end
    if isVisited then
        table.insert(tags, "discovered")
    end
    local label = ring.code .. "  " .. ring.location
    if #tags > 0 then
        label = label .. "  [" .. table.concat(tags, ", ") .. "]"
    end
    return label
end

-- List line for a multi-code destination, e.g. "DIR > AKS  Kethsi".
function Display.SequenceLabel(sequence)
    return table.concat(sequence.codes, " > ") .. "  " .. sequence.location
end

-- The details block for the selected ring.
--   visitState : "game" (seen in the game's own fairy ring windows or data),
--                "manual" (marked by hand), or nil (not discovered)
function Display.Details(ring, visitState)
    local lines = {}
    table.insert(lines, colour(ring.code, HIGHLIGHT_COLOUR) .. "  " .. ring.location)

    if ring.requirement then
        table.insert(lines, "Needs: " .. ring.requirement)
    else
        table.insert(lines, colour("No extra requirements", MUTED_COLOUR))
    end
    if ring.setup and visitState == nil then
        table.insert(lines, colour(ring.setup.detail, WARNING_COLOUR))
    elseif ring.setup then
        table.insert(lines, colour("Set up already (you've used this ring)", MUTED_COLOUR))
    end
    if ring.note then
        table.insert(lines, "Tip: " .. ring.note)
    end
    if ring.added then
        table.insert(lines, "Added " .. Dates.Format(ring.added))
    end
    for _, suggestion in ipairs(Favourites.For(ring.code)) do
        local label = suggestion.list == "clues" and "clues" or "travel"
        table.insert(lines, colour("Suggested favourite for " .. label .. " (#" .. suggestion.rank .. "): ",
            HIGHLIGHT_COLOUR) .. suggestion.reason)
    end
    if visitState == "game" then
        table.insert(lines, "Discovered (seen in your travel log)")
    elseif visitState == "manual" then
        table.insert(lines, "Discovered (marked by you)")
    else
        table.insert(lines, colour("Not discovered yet", MUTED_COLOUR))
    end
    return table.concat(lines, "<br>")
end

-- The details block for a multi-code destination.
function Display.SequenceDetails(sequence)
    return colour(table.concat(sequence.codes, " > "), HIGHLIGHT_COLOUR) .. "  " .. sequence.location
        .. "<br>Dial each code in order without leaving the ring."
        .. "<br>Needs: " .. sequence.requirement
end

-- Summary line under the title, e.g. "56 rings | 12 discovered | 7 need work before first use".
function Display.Summary(rings, visitedSet)
    local visitedCount, setupCount = 0, 0
    for _, ring in ipairs(rings) do
        if visitedSet[ring.code] then
            visitedCount = visitedCount + 1
        end
        if ring.setup and not visitedSet[ring.code] then
            setupCount = setupCount + 1
        end
    end
    return #rings .. " rings | " .. visitedCount .. " discovered | "
        .. setupCount .. " need work before first use"
end

-- Footer reminding the player of the requirements every ring shares.
function Display.BaseRequirements()
    return colour("Every ring needs: " .. table.concat(Rings.BASE_REQUIREMENTS, "; ") .. ".",
        MUTED_COLOUR)
end

-- Shown in the details area before anything is selected.
function Display.Hint(matchCount, modeKey)
    if matchCount == 0 then
        return colour("No rings match. Try a different search or filter.", MUTED_COLOUR)
    end
    if modeKey == "clues" or modeKey == "travel" then
        return colour("Best first. To use them, set them as numbered favourites in the "
            .. "fairy ring's travel log; then the number keys pick them.<br>"
            .. "Select one to see why it is suggested.", MUTED_COLOUR)
    end
    return colour("Select a ring to see its requirements.", MUTED_COLOUR)
end

return Display
