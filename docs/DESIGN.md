# Design notes

Written October 22nd, 2026, against the RS3 Client API docs at
developer.runescape.com.

## Data flow

```
  rings.lua ------> filter.lua ---> display.lua ---> panel.lua
  favourites.lua --/ (search,        (wording)        (ribbon window)
                      filters)
                         ^
  visited.lua -----------+  <--- log_reader.lua  (game's travel log, while open)
  (PersistentDB,            <--- game_source.lua (a variable, if one exists)
   per character)           <--- "Mark as discovered" button
```

- **rings.lua** is plain data. It is the only file that changes when Jagex
  adds a ring.
- **filter.lua** and **display.lua** are pure functions, fully unit tested.
- **panel.lua** builds the window each time the game opens it
  (`ContentLayerReady` gives a fresh, empty layer) and never holds state of its
  own; `main.lua` keeps the search text, filter and selection.

## Decisions

- **Static data, not live lookups.** The Wiki has no data module for fairy
  rings (only tables on the article), and live lookups would need the
  `httpAccess` permission and review. A static list is instant, needs no
  permissions, and is easy to check in a pull request.
- **Discovery by reading the travel log.** The game only lists rings you've
  visited, so any code or place name in its fairy ring windows counts as
  discovered. Detected rings are saved (`detected:<name>`) because they never
  become undiscovered. Manual marks are kept separately (`visited:<name>`).
- **Matching is strict.** Codes must stand alone (so "DISCOVERED" doesn't
  match DIS) and must be real ring codes. The Zanaris place name is ignored,
  because the screens mention Zanaris as the hub.
- **Detected rings win.** If the game shows a ring as discovered, the panel
  doesn't offer to unmark it.
- **Favourites are suggestions only.** Setting the game's favourites would be
  an action sent to the server, so the plugin lists them and explains how to
  set them instead.
- **No dialling, no clicking.** The plugin never interacts with the fairy ring
  interface. That keeps it firmly inside the guidelines and away from
  "modifying interfaces" review.
- **Multi-code destinations** only appear under "All rings", so filters like
  "need work" stay about single rings.

## Open questions (answer on the beta world)

1. **Window IDs** of the dial screen and travel log → `tools/fairy-discovery`
   prints `FAIRY WINDOW?` lines. Also: can an interface list its components
   (`IterateStaticComponents`), or is the per-ID fallback needed? Does the log
   build all rows up front, or only visible ones?
2. **Is there a variable for visited rings?** Same tool. Possibly one bit per
   ring across a few varbits.
3. **List behaviour.** Does `ui.List:Clear()` fire `ONSELECTIONCHANGED`? Does
   `DROPDOWN_DEFAULT` with `dropdownMaxVisibleEntries = 0` scroll as expected?
4. **Panel size.** The ribbon content layer's size isn't documented. The panel
   is about 600 px tall.
5. **Markup.** Do `<col=...>` and `<br>` work in `ui.Text`?
6. **Player name.** `Player.GetEntity().displayName` is used as the storage
   key; confirm it is available shortly after login.

## Ideas for later

- Show requirements as met/unmet using quest and skill data
  (`QuestType`, `Player.GetLevelUncapped`).
- A world-map style view instead of a list.
