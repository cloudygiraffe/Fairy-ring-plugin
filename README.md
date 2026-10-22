# Fairy Ring Codes

[![Tests](https://github.com/cloudygiraffe/Fairy-ring-plugin/actions/workflows/tests.yml/badge.svg)](https://github.com/cloudygiraffe/Fairy-ring-plugin/actions/workflows/tests.yml)
![Version](https://img.shields.io/badge/version-0.1.0-blue)
![Lua](https://img.shields.io/badge/Lua-5.4-2C2D72)
![Licence](https://img.shields.io/badge/licence-MIT%20%2F%20CC%20BY--NC--SA%203.0-lightgrey)

A RuneScape 3 plugin, built on the official Client API, that lists **every**
fairy ring, including the ones you've never visited. It reads your travel log
straight from the game to show which rings you still haven't discovered, and
warns you about rings that have to be repaired or built before they work.

> **Status: beta (0.1.0).** Runs on the plugin beta world. Automatic
> discovery was confirmed against the in-game travel log on October 22nd,
> 2026. Not yet submitted to the Plugin Hub.

## Contents

- [Features](#features)
- [Installation](#installation)
- [Usage](#usage)
- [Permissions](#permissions)
- [How it works](#how-it-works)
- [Ring data](#ring-data)
- [Project structure](#project-structure)
- [Development](#development)
- [Known issues and roadmap](#known-issues-and-roadmap)
- [Plugin guidelines](#plugin-guidelines)
- [Contributing](#contributing)
- [Licence and credits](#licence-and-credits)

## Features

- **Every ring in one list.** All 56 single-code rings, plus the three
  destinations that take several codes in a row (Kethsi, the Fairy Queen's
  Hideout and Ork's Rift). The game's own travel log only lists rings you've
  already been to, so new rings (four were added in 2026) are easy to miss.
- **Automatic discovery.** Your travel log is read from the game's variables:
  no permissions, no window to open. Rings you've visited are tagged
  `[discovered]`, and the **Not discovered yet** filter shows the rest.
- **Repair and build warnings.** Seven rings won't work until you repair them,
  build them or fix the bridges to them. They're tagged `[needs repair]`,
  `[needs building]` or `[needs bridges repaired]`, and the details say
  exactly what to bring. The tag disappears once you've used the ring.
- **Search** by code (`DKR`, `d k r`, or just `dk`) or by place (`canifis`).
- **Filters:** all rings, not discovered yet, suggested favourites for clues,
  suggested favourites for travel, need repairing or building, added
  recently, and rings with a quest or skill requirement.
- **Suggested favourites,** best first, with a reason for each. The clue list
  favours elite and master scan areas with no nearby lodestone. The travel
  list favours rings near popular training spots and bosses.
- **Manual marks** for anything the automatic check misses. Everything is
  saved separately for each character.

### Rings that need work before first use

| Code | Where | What to do |
|---|---|---|
| AKP | Your house | Build it: 85 Construction, 10 bittercap mushrooms, a fairy enchantment from Fairy Fixit |
| BJP | Fort Forinthry | Appears once the Fort's Grove reaches tier 2 |
| BJQ | Ancient Cavern | Repair: 5 bittercap mushrooms and a spade |
| BJS | The Lost Grove | Repair: 5 bittercap mushrooms and a spade |
| CJS | Kharazi Jungle | Repair: 5 bittercap mushrooms and a spade |
| DIP | Mos Le'Harmless | Repair the bridges: 8 planks, 16 nails, a hammer |
| DIQ | Fenmoor, Havenhythe | Repair: 5 bogwart mushrooms and a spade |

## Installation

Until the plugin is approved, it only runs on the **plugin beta world**.
Your beta character is a copy of your live one (press **import save** in the
lobby, at most once an hour), so nothing you do there affects your real
account.

1. Join the beta through
   [developer.runescape.com → Accessing the API](https://developer.runescape.com/rs/tutorial/1helloworld.html).
2. Open the beta client folder, on Windows usually
   `C:\ProgramData\Jagex\RuneScape-BETA`. It's a hidden folder, so paste the
   path into the address bar.
3. Create a `dev_plugins` folder there if there isn't one.
4. Copy the `fairy-ring-codes` folder into `dev_plugins`. Copy the folder
   itself, so you end up with `dev_plugins\fairy-ring-codes\plugin.json`.
5. In game, open the console with **Alt + the key under Esc** and run:

| Command | What it does |
|---|---|
| `prf` | Rescans `dev_plugins` for plugins |
| `plist` | Lists plugins and any load errors |
| `pon fairy-ring-codes` | Turns the plugin on |
| `poff fairy-ring-codes` | Turns it off |
| `prl fairy-ring-codes` | Reloads it after you change a file |

If a panel was open when you reloaded, close it and open it again from the
Plugins ribbon to get the new version.

## Usage

Open **Fairy Rings** from the Plugins ribbon window.

- The summary line reads like `56 rings | 48 discovered | 1 need work before first use`.
- Type in the search box to narrow the list, or pick a filter from the dropdown.
- Select a ring to see its requirement, any repair or build steps, tips, the
  date it was added and, if it's a suggested favourite, why.
- **Mark as discovered** / **Mark as not discovered** sets a manual mark. The
  button is hidden for rings the game already reports as discovered.
- The plugin can't set the game's favourites for you; see
  [Plugin guidelines](#plugin-guidelines). To use the suggestions, set them as
  numbered favourites in the fairy ring's travel log. The number keys then
  pick them.

## Permissions

None. Everything is read from the game client, and nothing is sent anywhere.
The manifest declares no required or optional permissions.

## How it works

```
rings.lua (data) ---> filter.lua ---> display.lua ---> panel.lua
favourites.lua ---/   (search,        (wording)        (ribbon window)
                       filters)
                          ^
visited.lua --------------+  <--- sources/game_source.lua  travel-log variables (primary)
(per character)              <--- sources/log_reader.lua   open windows (backup)
                             <--- "Mark as discovered" button
```

**Travel-log variables (primary source).** The game stores your travel log
as one bit per code: the varbits `FAIRYRINGS_LOG_AIP` (-12080) to
`FAIRYRINGS_LOG_DLS` (-12143). They're packed into VarPlayers 2482 and 2483,
in dial order (A–D, then I–L, then P–S). None of this is documented by
Jagex. The names come from the client's own variable list (console command
`pan VarPlayer`). On the beta world on October 22nd, 2026, the codes read this
way matched the in-game travel log. `game_source.lua` reads them every 10
server ticks (about 6 seconds), and straight away when the game sends a
change. If the varbits can't be read, it falls back to the two whole
VarPlayers and splits out the bits itself.

**Window reader (backup).** `log_reader.lua` can also pick ring codes and
place names out of the text of the game's travel log and dial screen while
they're open. It's inactive until their interface IDs are added
(`tools/fairy-discovery` prints them as `FAIRY WINDOW?` lines).

**Setup tags.** A ring you've used has obviously been repaired or built, so
the `[needs …]` tag and the summary's "need work" count only cover rings you
haven't discovered.

**Favourites.** The clue list leans on elite and master scan areas with no
lodestone, where the Wiki describes dig spots from the fairy ring. The travel
list is a judgement call, and suggestions are welcome. Zanaris (AIP) is never
suggested, since the ring's own right-click option goes there.

**Storage.** `PersistentDB` is shared by every character on the computer, so
manual marks and window-detected rings are saved under per-character keys
(`visited:<name>`, `detected:<name>`). The travel-log variables aren't saved;
they're re-read after each login.

## Ring data

`fairy-ring-codes/src/rings.lua` holds every ring as plain data:

- **56 working codes**, each with a location (as the travel log names it), an
  area, an optional requirement, optional setup steps, the date added (for
  rings since 2017) and an optional tip.
- **8 dead codes** that lead nowhere: AJP, AKR, BLS, CIR, CJP, CJQ, CLQ and
  DJQ. DJQ only works as part of a sequence.
- **3 sequences**, for destinations reached by dialling several codes in a row.

A test checks that the working and dead codes together cover all 64 dial
combinations exactly once.

**Updating it.** When Jagex adds a ring, add one entry to `rings.lua`, bump
`Rings.DATA_VERSION`, and move `Filter.RECENT_SINCE` forward if the "Added
recently" filter should start from a later date. Then run the tests. The
travel-log bit for the new code is already handled, because all 64 codes are
read.

The ring data comes from the [RuneScape Wiki](https://runescape.wiki/w/Fairy_ring)
and is shared under CC BY-NC-SA 3.0. See [Licence and credits](#licence-and-credits).

## Project structure

```
fairy-ring-codes/              the plugin (this folder goes in dev_plugins)
  plugin.json                  manifest
  main.lua                     wires game events and the panel to the modules
  src/
    rings.lua                  ring data (CC BY-NC-SA 3.0)
    dates.lua                  US-style date formatting and comparison
    filter.lua                 search and filter logic (pure)
    favourites.lua             suggested favourites for clues and travel
    display.lua                every string shown to the player (pure)
    visited.lua                discovered rings, per character
    panel.lua                  the ribbon window
    sources/
      game_source.lua          travel-log variables (primary)
      log_reader.lua           text of open fairy ring windows (backup)
tools/fairy-discovery/         developer tool for the beta world; not for release
tests/
  run_tests.lua                unit tests
  mock_game_test.lua           end-to-end test against a strict fake game API
docs/
  DESIGN.md                    design decisions and findings
  TESTING.md                   beta-world test plan
.github/workflows/tests.yml    CI: syntax check and both test suites
```

## Development

You'll need **Lua 5.4** (`sudo apt-get install lua5.4`, `brew install lua`,
or [LuaBinaries](https://luabinaries.sourceforge.net/) on Windows). From the
repository root:

```sh
lua5.4 tests/run_tests.lua        # unit tests
lua5.4 tests/mock_game_test.lua   # loads main.lua against a fake game client
```

- **Unit tests** cover the ring data, search and filters, favourites, display
  text, visited tracking, text extraction from windows, and the travel-log
  bit maths.
- **The mock game test** runs the real `main.lua` against a fake client API.
  The fake is strict: reading an unknown API member, or setting an
  undocumented component property, fails the test. Where the real beta
  client behaved differently from the docs, the fake copies the real
  behaviour. For example, `List:Clear()` leaves old rows behind, which is why
  the panel uses `SetEntries`.

CI runs `luac5.4 -p` on every Lua file and then both suites, on every push and
pull request.

For testing in the game, see [docs/TESTING.md](docs/TESTING.md). For the
reasoning behind the design, see [docs/DESIGN.md](docs/DESIGN.md).

## Known issues and roadmap

- **Totals don't match the game's yet.** The game's travel log counts 58
  destinations: the 56 rings, plus the Fairy Queen's Hideout
  (`FAIRYRINGS_LOG_HIDEOUT`, varbit -12077) and Ork's Rift
  (`FT3_FAIRYRINGS_LOG_RIFT`, varbit -9964). The plugin doesn't read those two
  flags yet.
- **One discovered ring is unexplained.** On October 22nd, 2026, the travel
  log showed 51 discovered, but the code bits plus the Hideout and Rift flags
  added up to 50. One entry is stored somewhere else; finding it needs a
  comparison with the in-game log.
- **"Repaired but not visited."** The game has flags for some repairs:
  `FAIRYRING_KHARAZI_UNLOCKED` (-36857), `FAIRYRING_THE_LOST_GROVE_UNLOCKED`
  (-30277) and `FAIRYRING_FENMOOR_UNLOCKED` (-62149). Reading them would let
  the `[needs repair]` tag clear before your first visit.
- **Your in-game favourites.** `FAIRYRINGS_FAVOURITE_1` to `_10` (varbits
  -48976 to -48985, 10 bits each) hold the game's numbered favourites. The
  panel could show them next to the suggestions.
- **Met / unmet requirements,** using quest and skill data (`QuestType`,
  `Player.GetLevelUncapped`).
- **Before submitting:** replace `contactEmailAddress` in `plugin.json`, and
  go through [docs/TESTING.md](docs/TESTING.md).

## Plugin guidelines

- Shows only public information (the Wiki's ring list) and your own progress.
- Only reads your travel log and the game's fairy ring windows. It never
  clicks, scrolls, dials or changes anything, and never sets favourites for
  you.
- Never sends input or performs actions on your behalf.
- Needs no permissions and makes no network requests.

### How this differs from the existing "Fairy Rings" plugin

J3's Fairy Rings plugin (previewed by Jagex in August 2026) adds a search bar
to the game's fairy ring screen, made with clue scrolls in mind. This plugin
is a reference for every ring, including unvisited ones, with requirements
and repair steps. The two can sit side by side.

## Contributing

Issues and pull requests are welcome. See [CONTRIBUTING.md](CONTRIBUTING.md)
for setup, code conventions, and quirks of the beta client worth knowing
about. Notable changes are listed in [CHANGELOG.md](CHANGELOG.md).

## Licence and credits

- Code: [MIT](LICENSE).
- Ring data in `fairy-ring-codes/src/rings.lua` comes from the
  [RuneScape Wiki](https://runescape.wiki/w/Fairy_ring) and is shared under
  [CC BY-NC-SA 3.0](https://creativecommons.org/licenses/by-nc-sa/3.0/), with
  credit to the Wiki's contributors.
- Written with AI assistance (Claude). Per Jagex's AI policy, the submitting
  author reviews and understands every line before anything is submitted.
- Not affiliated with or endorsed by Jagex. RuneScape is a trademark of Jagex
  Ltd.
