# Testing on the plugin beta world

Plugins only run on the beta world until Jagex approves them. Your beta
character is a copy of your live one (press **import save** in the lobby, at
most once an hour), so nothing you do there affects your real account.

Before testing in game, run the automated tests from the repository root.
See the README's [Development](../README.md#development) section.

## 1. Set up

1. Join the beta through
   [developer.runescape.com → Accessing the API](https://developer.runescape.com/rs/tutorial/1helloworld.html),
   then press **import save** in the lobby.
2. Open the beta client folder, on Windows usually
   `C:\ProgramData\Jagex\RuneScape-BETA`. It's hidden, so paste the path into
   the address bar.
3. Create a `dev_plugins` folder inside it if there isn't one.
4. Copy these folders into `dev_plugins` (the folders themselves):
   - `fairy-ring-codes`
   - `tools/fairy-discovery` (optional, for the `TRAVEL LOG` readout)
5. Open the console with **Alt + the key under Esc**. Run `prf`, then `plist`.
   Both plugins should be listed with no `[ERROR]` lines.

Console commands: `pon <name>`, `poff <name>`, `prl <name>` (reload), `plist`.
After `prl`, close and reopen the plugin's panel to get the new version.

## 2. Compare with the in-game travel log (about 5 minutes)

1. Run `pon fairy-discovery`. After a few seconds it prints:
   - `TRAVEL LOG: <n> codes marked: …`, every code the game has marked as
     discovered.
   - `TRAVEL LOG extras: HIDEOUT=… RIFT=… …`, the multi-code destinations and
     the repair flags.
2. Open a fairy ring's travel log in game and note **Discovered: x/y**.
3. Check that x = the marked codes + HIDEOUT + RIFT. If it doesn't add up,
   find the entry that's in the log but not in the readout, and report it.
4. Optional, for the backup window reader: open the dial screen and the
   travel log. The console prints `FAIRY WINDOW? interface=…` with sample
   text. Those interface IDs go into `log_reader.lua`.
5. Run `poff fairy-discovery`.

## 3. Test the plugin

Run `pon fairy-ring-codes`, then open **Fairy Rings** from the Plugins
ribbon.

### Panel
- [ ] The plugin's icon appears in the Plugins ribbon window and the panel opens.
- [ ] The summary reads `56 rings | <n> discovered | <m> need work before first use`.
- [ ] The list scrolls and shows all rings, plus Kethsi, the Fairy Queen's
      Hideout and Ork's Rift at the bottom.
- [ ] The filter dropdown opens over the list, not underneath it.
- [ ] Everything fits. Note anything cut off, and your interface scale.
- [ ] `<col=…>` colours and `<br>` line breaks render as formatting, not as text.

### Automatic discovery
- [ ] Within a few seconds of logging in, without opening anything, the
      "discovered" count matches the `TRAVEL LOG` readout (the number of
      codes marked).
- [ ] Spot-check a few: rings in your travel log are tagged `[discovered]`,
      rings missing from it aren't.
- [ ] **Not discovered yet** shows only rings missing from your log. Switch
      filters back and forth a few times; no stale rows should remain.
- [ ] Rings you've used no longer show `[needs repair]` or `[needs building]`.
- [ ] Teleport to a ring you've never visited. Within a few seconds it becomes
      `[discovered]` and the count goes up.

### Search and filters
- [ ] `dk` shows DKP, DKQ, DKR and DKS. `d k r` shows DKR. `havenhythe` shows
      three rings.
- [ ] **Need repairing or building** shows 7 rings.
- [ ] **Added recently** shows the 2026 rings (BKS, DIQ, DLP, AKP).
- [ ] Closing and reopening the panel keeps the search and the filter.

### Suggested favourites
- [ ] Both favourites filters list rings best first, and the details say why.
- [ ] Searching inside a favourites filter also matches the reason, for
      example `karamja`.

### Manual marks
- [ ] Selecting an undiscovered ring shows its details and a
      **Mark as discovered** button. The button is hidden for rings the game
      reports as discovered.
- [ ] Marking a ring updates its `[discovered]` tag and the summary.
- [ ] Marks survive `prl fairy-ring-codes` and a relog.
- [ ] A second character on the same computer has its own marks.

### Data spot checks
- [ ] Pick three rings you know and confirm that the codes and places match
      the game.
- [ ] If you haven't repaired one of the "needs repair" rings yet, check its
      instructions in game.

Report anything odd as a GitHub issue. Include the console output and,
ideally, a screenshot.
