# Design notes

This covers how the plugin is put together and why, plus what was learned
about the game client on the beta world. It was last updated October 22nd,
2026, against the RS3 Client API docs at developer.runescape.com and the
beta client of that date.

## Data flow

```
  rings.lua ------> filter.lua ---> display.lua ---> panel.lua
  favourites.lua --/ (search,        (wording)        (ribbon window)
                      filters)
                         ^
  visited.lua -----------+  <--- sources/game_source.lua  travel-log variables (primary)
  (PersistentDB,            <--- sources/log_reader.lua   open windows (backup)
   per character)           <--- "Mark as discovered" button
```

- **`rings.lua`** is plain data, and the only file that changes when Jagex adds
  a ring.
- **`filter.lua`**, **`display.lua`**, **`dates.lua`** and **`favourites.lua`**
  are pure functions with no game calls, and are fully unit tested.
- **`panel.lua`** builds the window each time the game opens it
  (`ContentLayerReady` hands over a fresh, empty layer). It holds no state of
  its own. `main.lua` keeps the search text, filter and selection, and
  reports clicks back through callbacks.
- **`main.lua`** wires everything together:
  - `ServerLogic` (every 0.6 s): spot a login or character switch, re-read
    the travel-log variables every 10 ticks and any open fairy ring window
    every 3 ticks.
  - `VarTransmit`: re-read straight away when a `FAIRYRINGS_LOG_*` variable
    changes.
  - The panel only refreshes when the set of discovered rings actually
    changes.

## Decisions

- **Static data, not live lookups.** The Wiki has no data module for fairy
  rings, only tables in the article, and live lookups would need the
  `httpAccess` permission and a review. A static list is instant, needs no
  permissions, and is easy to check in a pull request.
- **The game's own variables are the primary source.** They need no
  permission, no open window and no scrolling, and they update the moment you
  reach a new ring. Reading window text was the original plan, and stays as a
  backup.
- **Visited state has three sources, and any one is enough.** Game-reported
  rings (`fromGame`) aren't saved, because they're re-read after each login.
  Rings detected in window text (`detected:<name>`) and manual marks
  (`visited:<name>`) are saved per character, because `PersistentDB` is
  shared across characters.
- **What the game reports wins.** If the game shows a ring as discovered, the
  panel doesn't offer to unmark it.
- **Used rings don't need work.** Setup tags and the "need work" count leave
  out discovered rings, since a ring you've teleported to has obviously been
  repaired or built.
- **Window-text matching is strict.** Codes must stand on their own (so
  "DISCOVERED" doesn't match DIS) and must be real ring codes. The place name
  Zanaris is ignored, because the fairy ring screens mention it as the hub.
- **Favourites are suggestions only.** Setting the game's favourites would be
  an action sent to the server, so the plugin lists them and explains how to
  set them instead.
- **No dialling, no clicking.** The plugin never interacts with the fairy ring
  interface. That keeps it well inside the guidelines and clear of the
  "modifying interfaces" review.
- **Multi-code destinations only appear under "All rings",** so filters like
  "need work" stay about single rings.

## Findings from the beta world (October 22nd, 2026)

| Question | Answer |
|---|---|
| Is there a variable for visited rings? | Yes: `FAIRYRINGS_LOG_<code>`, varbits -12080 (AIP) to -12143 (DLS), one bit per code in dial order, packed into VarPlayers 2482 (AIP–BLS) and 2483 (CIP–DLS). They matched the in-game travel log. The names come from the client's `pan VarPlayer` list. |
| What does the travel log's "Discovered: x/y" count? | `y` = 58: the 56 rings plus the Fairy Queen's Hideout (`FAIRYRINGS_LOG_HIDEOUT`, -12077) and Ork's Rift (`FT3_FAIRYRINGS_LOG_RIFT`, -9964). The test character showed 51 discovered against 50 from those flags; one entry is still unexplained. |
| Other useful variables | Repair flags `FAIRYRING_KHARAZI_UNLOCKED` (-36857), `FAIRYRING_THE_LOST_GROVE_UNLOCKED` (-30277), `FAIRYRING_FENMOOR_UNLOCKED` (-62149); in-game favourites `FAIRYRINGS_FAVOURITE_1..10` (-48976 to -48985, 10 bits each). |
| Does `List:Clear()` + `Add()` refresh a list? | Not reliably: old rows stayed, so a filtered list still showed rings it should have hidden. `List:SetEntries` works, so the panel uses it and maps row IDs back by label. |
| Do `<col=…>` and `<br>` work in `ui.Text`? | `<col=…>` yes (the gold title renders). `<br>` in the details area still to confirm. |
| Does a plain scrolling list work (`DROPDOWN_DEFAULT` with `dropdownMaxVisibleEntries = 0`)? | Yes. |
| `plugin.json` | The client rejects empty `"requiredDependencies": []` (and `optionalDependencies`), so leave the field out. Empty permission lists are fine. |

## Still open

1. **Window IDs** of the dial screen and travel log, which are only needed
   for the backup reader. `tools/fairy-discovery` prints them as
   `FAIRY WINDOW?` lines.
2. **The missing discovered entry** (51 vs 50). Compare the `TRAVEL LOG`
   readout with the in-game log to find which entry is stored somewhere else.
3. **Panel size.** The size of the ribbon content layer isn't documented. The
   panel is about 600 px tall; check that nothing is cut off at other
   interface scales.

## Ideas for later

- Count the Hideout and Rift, so the totals match the game's.
- Show "repaired" for the three rings with a repair flag before you first
  visit them.
- Show the player's current in-game favourites next to the suggestions.
- Show requirements as met or unmet, using quest and skill data (`QuestType`,
  `Player.GetLevelUncapped`).
- A map-style view instead of a list.
