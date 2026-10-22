# Fairy Ring Codes — RuneScape 3 plugin

Every RS3 fairy ring in one searchable list, **including rings you have never
visited**, with what each one needs and which rings must be **repaired or
built** before you can teleport there.

> **Status: pre-release (0.1.0).** The code is complete and tested outside the
> game, but it has not run in the game client yet. See
> [docs/TESTING.md](docs/TESTING.md).

## Why

- The game's travel log only lists rings you have already visited, and since
  the February 2021 update the dial only names a destination once you have
  been there. New rings (four were added in 2026 alone) don't show up until
  you find them yourself.
- Some rings won't work until you do something first: repair them with
  mushrooms, build them, or fix the bridges to them. Nothing in game tells you
  that until you arrive and it fails.

## What it does

The panel (open from the Plugins ribbon window) has:

- **Search** by code (`DKR`, `d k r`, or just `dk`) or by place (`canifis`).
- **Filters:** all rings, not visited yet, need repairing or building, added
  recently, or have a quest or skill requirement.
- **The list** of all 56 single-code rings, plus the three destinations that
  take several codes in a row (Kethsi, the Fairy Queen's Hideout, Ork's Rift).
  Tags show `[needs repair]`, `[needs building]`, `[new]` and `[visited]`.
- **Details** for the selected ring: its requirement, exactly what to do if it
  needs repairing or building, tips, and when it was added.
- **Mark as visited**, saved separately for each character.
- A reminder of the quests every ring needs.

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

## How this differs from the existing "Fairy Rings" plugin

J3's Fairy Rings plugin (previewed by Jagex in August 2026) adds a **search
bar to the game's fairy ring screen**, made with clue scrolls in mind. This
plugin is a **reference of every ring**, including unvisited ones, with
requirements and repair/build steps. They could sit side by side. If J3 ever
covers unvisited rings, it would be worth merging efforts rather than
duplicating.

## Visited status

The game clearly tracks which rings you've visited, but the variable isn't
documented. For now you can mark rings by hand. The discovery tool in
`tools/fairy-discovery` is built to find the game's own record on the beta
world; once found, it goes into `src/sources/game_source.lua` and visits fill
in automatically.

## Plugin guidelines

- Shows only public information (the Wiki's ring list) and your own progress.
- Never sends input or performs actions. It does not dial rings for you.
- Needs no permissions.

## Repository layout

```
fairy-ring-codes/        the plugin itself (this folder goes in dev_plugins)
  plugin.json            manifest
  main.lua               wires events and the panel together
  src/
    rings.lua            every ring: code, place, requirement, setup, date
    dates.lua            US-style date formatting
    filter.lua           search and filter logic
    display.lua          all text shown to the player
    visited.lua          visited marks, saved per character
    panel.lua            the ribbon panel
    sources/
      game_source.lua    the game's own visited record (after discovery)
tools/fairy-discovery/   beta-world tool that looks for that record
tests/                   unit tests and an end-to-end test with a fake API
docs/DESIGN.md           how it works and open questions
docs/TESTING.md          step-by-step beta world testing
```

## Running the tests

With any Lua 5.1 or newer interpreter, from the repository root:

```
lua tests/run_tests.lua
lua tests/mock_game_test.lua
```

The data tests check, among other things, that the 56 working codes and 8
dead codes cover all 64 dial combinations exactly once.

## Keeping the list up to date

When Jagex adds a ring, add one entry to `fairy-ring-codes/src/rings.lua` and
update `DATA_VERSION` (and `Filter.RECENT_SINCE` for the "Added recently"
filter). The tests will catch duplicate or impossible codes.

## Before submitting to the Plugin Hub

- [ ] Replace `contactEmailAddress` in `plugin.json`.
- [ ] Test every item in [docs/TESTING.md](docs/TESTING.md).
- [ ] Wire up `game_source.lua` if the discovery tool finds the variable.
- [ ] Re-read every file: Jagex's AI policy requires the author to have reviewed
      and understood all submitted code.

## Credits and licence

- Ring data comes from the [RuneScape Wiki](https://runescape.wiki/w/Fairy_ring).
  `fairy-ring-codes/src/rings.lua` is therefore shared under
  [CC BY-NC-SA 3.0](https://creativecommons.org/licenses/by-nc-sa/3.0/), with
  credit to the RuneScape Wiki contributors.
- All other code is [MIT](LICENSE).
- Written with AI assistance (Claude). Per Jagex's AI policy, the author reviews
  and understands every line before anything is submitted.
