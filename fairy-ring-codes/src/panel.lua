-- panel.lua
-- The plugin's window, opened from its icon in the Plugins ribbon window.
--
-- The game hands the plugin an empty layer every time the window is shown
-- (the ContentLayerReady event), so Build() recreates the components each
-- time and Refresh() fills them in.
--
-- Layout, top to bottom:
--   title and summary ("56 rings | 12 discovered | 7 need work before first use")
--   search box
--   filter dropdown (all, not discovered, suggested favourites, need work, ...)
--   the list of matching rings
--   details for the selected ring
--   "Mark as discovered" button
--   the requirements every ring shares

local Filter = require("src/filter")

local Panel = {}
Panel.__index = Panel

local FONT = id.Font.MUSEO_SANS_15PT_REGULAR
local LINE = 20         -- height of a one-line text row
local GAP = 4           -- space between rows
local CONTROL = 28      -- height of the search box, dropdown and button
local LIST_HEIGHT = 240 -- about 11 rings visible; the list scrolls
local DETAIL_ROWS = 8

-- Sequence entries in the list get IDs above this, so they never clash with
-- ring IDs (which are their position in Rings.LIST).
Panel.SEQUENCE_ID_OFFSET = 1000

-- callbacks:
--   onSearchChanged(text)
--   onFilterChanged(modeId)
--   onSelected(entryId)
--   onToggleVisited()
function Panel.new(callbacks)
    local self = setmetatable({}, Panel)
    self.callbacks = callbacks
    self.root = nil
    self.parts = {}
    return self
end

-- Adds a full-width text row at vertical position y and returns it.
local function addText(parent, y, rows)
    local text = ui.Text.new(parent)
    text:SetPos(0, y)
    text:SetSize(0, LINE * rows, 1.0, 0.0) -- full parent width
    text.font = FONT
    text.maxLines = rows
    -- ui.AlignMode has TOPLEFT, CENTRE, BOTTOMRIGHT and JUSTIFY; TOPLEFT means
    -- "left" when used horizontally and "top" when used vertically.
    text:AlignTo(ui.AlignMode.TOPLEFT, ui.AlignMode.TOPLEFT)
    text.content = ""
    return text
end

-- Reads the ID of the selected entry in a single-selection list, or nil.
local function selectedId(list)
    local ok, entryId = pcall(function()
        local selected = list.selectedEntries
        if selected and selected[1] then
            return selected[1].id
        end
        return nil
    end)
    if ok then
        return entryId
    end
    return nil
end

-- Creates every component on the layer the game provided.
--   searchText : current search text (kept when the window reopens)
--   modeId     : current filter
function Panel:Build(root, searchText, modeId)
    self.root = root
    self.parts = {}
    local parts = self.parts
    local y = 0

    parts.title = addText(root, y, 1)
    parts.title.content = "<col=ffd24a>Fairy Rings</col>"
    y = y + LINE + GAP

    parts.summary = addText(root, y, 1)
    y = y + LINE + GAP

    -- Search box.
    local search = ui.InputField.new(root)
    search:SetPos(0, y)
    search:SetSize(0, CONTROL, 1.0, 0.0)
    search.stylesheetID = id.StyleSheet.INPUT_DEFAULT
    search.emptyText = "Search a code or place, e.g. DKR or Canifis"
    search.content = searchText or ""
    search:Subscribe(ui.Hook.ONCONTENTCHANGED, function(component)
        self.callbacks.onSearchChanged(component.content)
    end)
    parts.search = search
    y = y + CONTROL + GAP

    -- Filter dropdown. Created after the list below would cover it, so it is
    -- moved to the front at the end of Build.
    local filterList = ui.List.new(root)
    filterList:SetPos(0, y)
    filterList:SetSize(0, CONTROL, 1.0, 0.0)
    filterList.stylesheetID = id.StyleSheet.DROPDOWN_DEFAULT
    filterList.dropdownMaxVisibleEntries = #Filter.MODES
    -- Added one by one (not with a name->ID map) so they keep this order.
    for _, mode in ipairs(Filter.MODES) do
        filterList:Add(mode.label, mode.id)
    end
    filterList:SetEntrySelected(modeId, true, false)
    filterList:Subscribe(ui.Hook.ONSELECTIONCHANGED, function(component)
        local chosen = selectedId(component)
        if chosen then
            self.callbacks.onFilterChanged(chosen)
        end
    end)
    parts.filter = filterList
    y = y + CONTROL + GAP * 2

    -- The ring list. DROPDOWN_DEFAULT with zero dropdown entries draws a
    -- plain scrolling list (as recommended on the Style Sheets doc page).
    local ringList = ui.List.new(root)
    ringList:SetPos(0, y)
    ringList:SetSize(0, LIST_HEIGHT, 1.0, 0.0)
    ringList.stylesheetID = id.StyleSheet.DROPDOWN_DEFAULT
    ringList.dropdownMaxVisibleEntries = 0
    ringList:Subscribe(ui.Hook.ONSELECTIONCHANGED, function(component)
        local chosen = selectedId(component)
        if chosen ~= nil then
            chosen = self:OurId(chosen)
        end
        if chosen then
            self.callbacks.onSelected(chosen)
        end
    end)
    parts.list = ringList
    y = y + LIST_HEIGHT + GAP * 2

    parts.details = addText(root, y, DETAIL_ROWS)
    y = y + LINE * DETAIL_ROWS + GAP

    local button = ui.Button.new(root)
    button:SetPos(0, y)
    button:SetSize(0, CONTROL, 0.5, 0.0) -- half width
    button.stylesheetID = id.StyleSheet.BUTTON_DEFAULT
    button.label = "Mark as discovered"
    button:Subscribe(ui.Hook.ONBUTTONPRESSED, function()
        self.callbacks.onToggleVisited()
    end)
    parts.button = button
    y = y + CONTROL + GAP * 2

    parts.footer = addText(root, y, 3)

    -- Make sure the open dropdown draws over the list below it.
    pcall(function() filterList:MoveToFront() end)
end

-- True if the panel is built and currently on screen.
function Panel:IsVisible()
    if self.root == nil then
        return false
    end
    local ok, visible = pcall(function() return self.root.visibleGlobal end)
    return ok and visible == true
end

-- Replaces the list contents. `entries` is a list of { id = n, label = "..." }.
-- The selected entry is kept if it is still in the list.
--
-- Uses SetEntries, which clears and refills the list in one call: on the
-- beta client, Clear() followed by Add() left old rows behind. SetEntries
-- gives the rows its own IDs, so they are mapped back to ours by label.
function Panel:SetListEntries(entries, keepSelectedId)
    if not self:IsVisible() then
        return
    end
    local list = self.parts.list
    local labels, ourIdByLabel = {}, {}
    for index, entry in ipairs(entries) do
        labels[index] = entry.label
        ourIdByLabel[entry.label] = entry.id
    end
    self.ourIdByRowId, self.rowIdByOurId = {}, {}

    local ok, done = pcall(function() return list:SetEntries(labels) end)
    if ok and done ~= false then
        pcall(function()
            for _, row in ipairs(list.entries) do
                local ourId = ourIdByLabel[row.text]
                if ourId then
                    self.ourIdByRowId[row.id] = ourId
                    self.rowIdByOurId[ourId] = row.id
                end
            end
        end)
    end
    if next(self.ourIdByRowId) == nil then
        -- SetEntries unavailable (or its rows unreadable): add rows one by one
        -- with our own IDs.
        self.ourIdByRowId, self.rowIdByOurId = nil, nil
        pcall(function()
            list:Clear()
            for _, entry in ipairs(entries) do
                list:Add(entry.label, entry.id)
            end
        end)
    end

    if keepSelectedId then
        local rowId = self.rowIdByOurId and self.rowIdByOurId[keepSelectedId] or keepSelectedId
        pcall(function()
            if list:HasEntry(rowId) then
                list:SetEntrySelected(rowId, true, false)
            end
        end)
    end
end

-- Turns a row ID from the ring list back into the ID main.lua gave it.
function Panel:OurId(rowId)
    if self.ourIdByRowId then
        return self.ourIdByRowId[rowId]
    end
    return rowId
end

-- Fills in the text areas. `view` is built by main.lua with:
--   summary, details, footer, buttonLabel (nil hides the button)
function Panel:SetText(view)
    if not self:IsVisible() then
        return
    end
    local parts = self.parts
    pcall(function()
        parts.summary.content = view.summary
        parts.details.content = view.details
        parts.footer.content = view.footer
        if view.buttonLabel then
            parts.button.label = view.buttonLabel
            parts.button.hidden = false
        else
            parts.button.hidden = true
        end
    end)
end

return Panel
