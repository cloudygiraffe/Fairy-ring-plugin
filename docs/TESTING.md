# Testing on the plugin beta world

Plugins only run on the beta world until Jagex approves them. Your beta
character is a copy of your live one ("import save" in the lobby, once an
hour), so nothing you do there affects your real account.

## 1. Set up

1. Join the beta using the link on
   [developer.runescape.com → Accessing the API](https://developer.runescape.com/rs/tutorial/1helloworld.html),
   then press **import save** in the lobby.
2. Find the beta client folder. On Windows it is usually
   `C:\ProgramData\Jagex\RuneScape-BETA`.
3. Create a `dev_plugins` folder inside it if there isn't one.
4. Copy these folders into `dev_plugins`:
   - `fairy-ring-codes`
   - `tools/fairy-discovery` (copy the `fairy-discovery` folder itself)
5. Open the console with **Alt + the key under Esc**. Run `prf`, then `plist`.

Console commands: `pon <name>`, `poff <name>`, `prl <name>` (reload), `plist`.

## 2. Find the fairy ring windows and the "visited" variable (about 15 minutes)

1. Run `pon fairy-discovery` and wait for `Scan complete`. Copy every `MATCH` line.
2. Open a fairy ring's **dial screen**, then its **travel log**. Within a few
   seconds the console should print `FAIRY WINDOW? interface=...` with sample
   text. Copy those lines; the interface IDs go into `log_reader.lua`. Scroll
   the log and note whether more text appears.
3. Teleport to a ring you have **never visited** on this character. Right-clicking the ring and choosing **Configure** starts a
   30-second capture.
4. Copy every `CHANGE` line printed after that. A variable that changes when
   you reach a new ring (and not on a repeat visit) is the one we want.
5. Repeat with a second never-visited ring to confirm the pattern.
6. Run `poff fairy-discovery` and paste the output into a GitHub issue.

## 3. Test the plugin

Run `pon fairy-ring-codes`.

### Panel
- [ ] The plugin's icon appears in the Plugins ribbon window and the panel opens.
- [ ] The summary reads "56 rings | 0 discovered | 7 need work before first use".
- [ ] The list scrolls and shows all rings plus Kethsi, the Fairy Queen's
      Hideout and Ork's Rift at the bottom.
- [ ] The filter dropdown opens over the list, not underneath it.
- [ ] Everything fits. Note anything cut off, and the panel's size.
- [ ] `<col=...>` colours and `<br>` line breaks render (not shown as text).

### Search and filters
- [ ] `dk` shows DKP, DKQ, DKR, DKS. `d k r` shows DKR. `havenhythe` shows three rings.
- [ ] "Need repairing or building" shows 7 rings.
- [ ] "Added recently" shows the 2026 rings (BKS, DIQ, DLP, AKP).
- [ ] Closing and reopening the panel keeps the search and filter.

### Automatic discovery (after the window IDs are in `log_reader.lua`)
- [ ] Open the travel log. Within a few seconds, rings listed there get the
      `[discovered]` tag and the summary count goes up.
- [ ] Scroll to the bottom of the log; anything further down is picked up too.
- [ ] "Not discovered yet" shows only rings missing from your log.
- [ ] Zanaris (AIP) is not marked unless it's actually listed in your log.

### Suggested favourites
- [ ] Both favourites filters list rings best first, and the details say why.

### Manual marks
- [ ] Selecting a ring shows its details and a "Mark as discovered" button
      (hidden for rings the game already shows as discovered).
- [ ] Marking a ring updates its `[discovered]` tag and the summary.
- [ ] Marks survive `prl fairy-ring-codes` and a relog.
- [ ] A second character on the same computer has its own marks.

### Data spot checks
- [ ] Pick three rings you know and confirm codes and places match the game.
- [ ] Check one "needs repair" ring in game, if you haven't repaired it yet.

Report anything odd as a GitHub issue with the console output and, ideally, a screenshot.
