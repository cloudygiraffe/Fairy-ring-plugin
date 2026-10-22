-- Fairy Ring Codes
-- Every RS3 fairy ring in one searchable list, including rings you have never
-- visited (which the game's own travel log leaves out), with what each one
-- needs and which rings must be repaired or built before the first teleport.
--
-- How the pieces fit together (see docs/DESIGN.md for more):
--
--   rings.lua (data) --> filter.lua (search + filter) --> display.lua (text)
--                                                              |
--   visited.lua (per-character marks) <--- game_source.lua     v
--                                                         panel.lua
--
-- This file only wires events and the panel to those modules.

local Rings = require("src/rings")
local Filter = require("src/filter")
local Display = require("src/display")
local Visited = require("src/visited")
local Panel = require("src/panel")
local GameSource = require("src/sources/game_source")
local LogReader = require("src/sources/log_reader")

--------------------------------------------------------------------------------
-- What the panel is currently showing
--------------------------------------------------------------------------------

local searchText = ""
local modeId = Filter.MODES[1].id
local selectedId = nil -- a ring index, or Panel.SEQUENCE_ID_OFFSET + sequence index
local loadedCharacter = nil

local panel -- created below

-- Looks up what a list entry ID refers to.
local function selectedItem()
    if selectedId == nil then
        return nil, nil
    end
    if selectedId > Panel.SEQUENCE_ID_OFFSET then
        return nil, Rings.SEQUENCES[selectedId - Panel.SEQUENCE_ID_OFFSET]
    end
    return Rings.LIST[selectedId], nil
end

-- Rebuilds the list for the current search and filter.
local function refreshList()
    local visitedSet = Visited.AsSet()
    local mode = Filter.ModeByID(modeId)
    local entries = {}

    local rings = Filter.Apply(Rings.LIST, searchText, mode.key, visitedSet)
    for _, ring in ipairs(rings) do
        table.insert(entries, {
            id = ring.index,
            label = Display.ListLabel(ring, visitedSet[ring.code], Filter.RECENT_SINCE),
        })
    end
    for index, sequence in ipairs(Rings.SEQUENCES) do
        for _, match in ipairs(Filter.ApplySequences({ sequence }, searchText, mode.key)) do
            table.insert(entries, {
                id = Panel.SEQUENCE_ID_OFFSET + index,
                label = Display.SequenceLabel(match),
            })
        end
    end

    panel:SetListEntries(entries, selectedId)
    return #entries
end

-- Updates the summary, details and button for the current selection.
local function refreshText(matchCount)
    local ring, sequence = selectedItem()
    local view = {
        summary = Display.Summary(Rings.LIST, Visited.AsSet()),
        footer = Display.BaseRequirements(),
    }
    if ring then
        local visitState = nil
        if Visited.IsDetected(ring.code) then
            visitState = "game"
        elseif Visited.Is(ring.code) then
            visitState = "manual"
        end
        view.details = Display.Details(ring, visitState)
        -- Rings the game itself shows as discovered cannot be unmarked by hand.
        if visitState == "game" then
            view.buttonLabel = nil
        elseif visitState == "manual" then
            view.buttonLabel = "Mark as not discovered"
        else
            view.buttonLabel = "Mark as discovered"
        end
    elseif sequence then
        view.details = Display.SequenceDetails(sequence)
        view.buttonLabel = nil
    else
        view.details = Display.Hint(matchCount or 1, Filter.ModeByID(modeId).key)
        view.buttonLabel = nil
    end
    panel:SetText(view)
end

local function refreshAll()
    local matchCount = refreshList()
    refreshText(matchCount)
end

--------------------------------------------------------------------------------
-- Panel
--------------------------------------------------------------------------------

panel = Panel.new({
    onSearchChanged = function(text)
        searchText = text or ""
        refreshAll()
    end,
    onFilterChanged = function(newModeId)
        modeId = newModeId
        refreshAll()
    end,
    onSelected = function(entryId)
        selectedId = entryId
        refreshText()
    end,
    onToggleVisited = function()
        local ring = selectedItem()
        if ring == nil or Visited.IsDetected(ring.code) then
            return
        end
        Visited.SetManual(ring.code, not Visited.Is(ring.code))
        refreshAll()
    end,
})

-- The game gives us a fresh, empty layer each time the window opens.
Event.ContentLayerReady.Subscribe("fairyPanel", function(event)
    panel:Build(event.component, searchText, modeId)
    refreshAll()
end)

--------------------------------------------------------------------------------
-- Game events
--------------------------------------------------------------------------------

-- Reads your travel log from the game's variables. Only refreshes the panel
-- when something actually changed.
local lastGameKey = nil
local function refreshFromGame()
    local visited = GameSource.ReadVisited()
    if visited == nil then
        return
    end
    local codes = {}
    for code in pairs(visited) do table.insert(codes, code) end
    table.sort(codes)
    local key = table.concat(codes, ",")
    if key ~= lastGameKey then
        lastGameKey = key
        Visited.SetFromGame(visited)
        refreshAll()
    end
end

-- How often to read the game's fairy ring windows while one is open, in
-- server ticks (0.6 s each). Re-reading lets scrolling reveal more rows.
local READ_EVERY_SERVER_TICKS = 3
-- How often to re-read the travel-log variables (they also trigger a re-read
-- when the game sends them, but this catches values that arrive after login).
local GAME_VARS_EVERY_SERVER_TICKS = 10
local serverTicks = 0

-- Reads the game's travel log / dial screen if one is open, and records any
-- rings shown there as discovered.
local function readGameWindows()
    if not LogReader.IsConfigured() or loadedCharacter == nil then
        return
    end
    local seen = LogReader.Read()
    if seen and Visited.AddDetected(seen) > 0 then
        refreshAll()
    end
end

-- Every server tick (0.6 s): load the right character's data after login or
-- a character switch, and read open fairy ring windows. Cheap when nothing
-- has changed.
Event.ServerLogic.Subscribe("fairyCharacter", function()
    serverTicks = serverTicks + 1
    if serverTicks % READ_EVERY_SERVER_TICKS == 0 then
        readGameWindows()
    end
    if serverTicks % GAME_VARS_EVERY_SERVER_TICKS == 0 and loadedCharacter ~= nil then
        refreshFromGame()
    end
    local ok, name = pcall(function()
        if Player.IsAvailable() then
            return Player.GetEntity().displayName
        end
        return nil
    end)
    if ok and name and name ~= loadedCharacter then
        loadedCharacter = name
        Visited.UseCharacter(name)
        lastGameKey = nil
        refreshFromGame()
        refreshAll()
    end
end)

-- The travel-log variables changed (e.g. you reached a new ring).
Event.VarTransmit.Subscribe("fairyVars", function(event)
    if GameSource.IsOurVariable(event) then
        refreshFromGame()
    end
end)
