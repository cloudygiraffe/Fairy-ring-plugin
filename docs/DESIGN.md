# Design notes

Written October 22nd, 2026, against the RS3 Client API docs at
developer.runescape.com.

## Data flow

```
  rings.lua ---> filter.lua ---> display.lua ---> panel.lua
  (static)       (search,         (wording)        (ribbon window)
                  filters)
                     ^
  visited.lua -------+   <--- game_source.lua (once the variable is known)
  (PersistentDB,              <--- "Mark as visited" button
   per character)
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
- **Per-character visited marks.** PersistentDB is shared by every character
  on the computer, so marks are stored under `visited:<display name>`.
- **Game-reported visits win.** If the game says a ring is visited, the panel
  doesn't offer to unmark it.
- **No dialling, no clicking.** The plugin never interacts with the fairy ring
  interface. That keeps it firmly inside the guidelines and away from
  "modifying interfaces" review.
- **Multi-code destinations** only appear under "All rings", so filters like
  "need work" stay about single rings.

## Open questions (answer on the beta world)

1. **Is there a variable for visited rings?** → `tools/fairy-discovery`.
   Possibly one bit per ring across a few varbits.
2. **List behaviour.** Does `ui.List:Clear()` fire `ONSELECTIONCHANGED`? Does
   `DROPDOWN_DEFAULT` with `dropdownMaxVisibleEntries = 0` scroll as expected?
3. **Panel size.** The ribbon content layer's size isn't documented. The panel
   is about 560 px tall.
4. **Markup.** Do `<col=...>` and `<br>` work in `ui.Text`?
5. **Player name.** `Player.GetEntity().displayName` is used as the storage
   key; confirm it is available shortly after login.

## Ideas for later

- Read the in-game travel log while it's open, as a second way to learn
  visited rings (plugins can read built-in interface text).
- Show requirements as met/unmet using quest and skill data
  (`QuestType`, `Player.GetLevelUncapped`).
- A world-map style view instead of a list.
