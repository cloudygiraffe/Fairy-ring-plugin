# Contributing

Thanks for helping. This guide covers setup, the conventions the code
follows, and a few quirks of the beta client worth knowing about before you
start.

## Setup

1. Fork and clone the repository.
2. Install **Lua 5.4**. It's what CI uses, and any 5.4 interpreter works.
3. Run both suites from the repository root. They should pass before you
   change anything:

   ```sh
   lua5.4 tests/run_tests.lua
   lua5.4 tests/mock_game_test.lua
   ```

4. To try a change in the game, copy `fairy-ring-codes/` into
   `C:\ProgramData\Jagex\RuneScape-BETA\dev_plugins\`, then run `prf` and
   `pon fairy-ring-codes` in the console (Alt + the key under Esc). After
   editing, run `prl fairy-ring-codes`, then close and reopen the panel. The
   full checklist is in [docs/TESTING.md](docs/TESTING.md).

## Code conventions

- **4-space indent,** no tabs. Keep lines to about 100 characters.
- **One module per file.** Each file builds a local table (`local Filter =
  {}`), adds functions to it, and returns it. Modules are loaded with
  `require("src/...")`, relative to the plugin folder.
- **Keep logic pure where you can.** `rings.lua`, `dates.lua`, `filter.lua`,
  `favourites.lua` and `display.lua` don't touch the game API, so they're
  unit tested directly. Put new decision-making code in a pure module, and
  keep `main.lua` and `panel.lua` to wiring and UI.
- **Wrap every game API call in `pcall`.** The API is new and the docs are
  incomplete, so a renamed field or an unexpected `nil` shouldn't take the
  whole plugin down. Wrap the call, then carry on with a sensible default.
- **Only use documented members.** The mock game test fails if the plugin
  reads an API member, or sets a component property, that isn't in the
  developer.runescape.com docs. If you need something new, add it to the fake
  in `tests/mock_game_test.lua` with a comment pointing to the doc page.
- **Mark what's documented and what was observed.** Anything learned by
  testing on the beta world, rather than from the docs, gets a comment saying
  "observed on the beta world" and the date. Undocumented variables in
  particular should be marked this way.
- **Store per-character data under per-character keys.** `PersistentDB` is
  shared by every character on the computer, so prefix keys with the
  character's name (see `visited.lua`).
- **Write dates the US way** in anything players see: "October 22nd, 2026"
  (`Dates.Format`).
- **Comments say why, not what.** Every file starts with a header covering
  its purpose, where it fits and its current status. Every public function
  says what it takes and returns.

## Beta client quirks

These were observed on the beta world on October 22nd, 2026, and may change
in later clients:

- **`ui.List:Clear()` followed by `Add()` left old rows in the list.** Use
  `List:SetEntries(labels)`, which clears and refills the list in one call,
  and map its auto-generated row IDs back to your own (see
  `Panel:SetListEntries`). The mock reproduces the `Clear()` behaviour.
- **`plugin.json` must not contain empty dependency lists.** The client
  rejected `"requiredDependencies": []` with "unexpected json Array, expected
  a json Object", so leave the field out when there are no dependencies.
  Empty permission lists (`"requiredPermissions": []`) load fine.
- **List row labels are plain text.** `<col=…>` markup only works in
  `ui.Text`, which is why tags in the ring list use brackets.
- If you reload a plugin while its panel is open, the old panel stays on
  screen until you close and reopen it.

## Adding or changing ring data

1. Edit `fairy-ring-codes/src/rings.lua`. The fields are documented at the
   top of the file. Use the location name the in-game travel log uses.
2. Bump `Rings.DATA_VERSION`. If you're adding a new batch of rings, also
   update `Filter.RECENT_SINCE`.
3. If a ring needs repairing or building before first use, add a `setup`
   entry, and update the table in the README.
4. Run the tests. They check for duplicate codes, impossible codes, and full
   coverage of all 64 dial combinations.
5. Cite your source in the pull request. The data is from the RuneScape Wiki
   (CC BY-NC-SA 3.0).

## Adding tests

- **Pure logic:** add a `test("description", function() ... end)` block to
  `tests/run_tests.lua`, using `eq(actual, expected, label)`.
- **Anything that touches the game API:** extend the scenario in
  `tests/mock_game_test.lua` and use `check(condition, message)`. Fire events
  with `fire("ServerLogic", nil)` and similar calls, and set fake variable
  values through the `gameVarbits` table.

## Developer tool

`tools/fairy-discovery` is a separate plugin for the beta world that prints
to the console. It's never meant for release. Its `TRAVEL LOG` readout is
the quickest way to compare what the plugin reads with the in-game travel
log. The client's own `pan VarPlayer` and `pan VarClient` console commands
copy the full variable lists to the clipboard.

## Pull request checklist

- [ ] Both test suites pass with Lua 5.4, and `luac5.4 -p` is clean (CI
      checks both).
- [ ] New behaviour has a test.
- [ ] Comments and docs are updated, including README, `docs/DESIGN.md`,
      `docs/TESTING.md` and `CHANGELOG.md` (under "Unreleased").
- [ ] Nothing automates input or acts on the player's behalf. See the plugin
      guidelines on developer.runescape.com.
- [ ] Tested on the beta world if the change touches the game API, with what
      you saw noted in the pull request.

## A note on Jagex's AI policy

Jagex requires whoever submits a plugin to the Plugin Hub to have reviewed and
understood all of its code, however it was written. Parts of this project were
written with AI assistance. Please review your own changes, and any you build
on, with that in mind.
