# Changelog

All notable changes to this project are documented here. The format is based
on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/), and the project
uses [Semantic Versioning](https://semver.org/).

## [Unreleased] - 0.1.0

First version, running on the plugin beta world. Not yet submitted to the
Plugin Hub.

### Added

- A ribbon panel listing all 56 single-code fairy rings, plus the Kethsi,
  Fairy Queen's Hideout and Ork's Rift code sequences.
- Search by code (with or without spaces, or partial) and by place name.
- Filters: all rings, not discovered yet, suggested favourites for clues and
  for travel, need repairing or building, added recently, and rings with a
  quest or skill requirement.
- Details for each ring: requirement, repair or build steps, tips, the date
  it was added, and why it's suggested as a favourite.
- Automatic discovery from the game's travel-log variables (varbits -12080
  to -12143), with no permissions needed. Confirmed against the in-game
  travel log on October 22nd, 2026.
- Setup tags (`[needs repair]`, `[needs building]`, `[needs bridges
  repaired]`) that clear once a ring has been used.
- Manual "Mark as discovered" marks, saved per character.
- A backup reader for the text of open fairy ring windows. It's inactive
  until the window IDs are known.
- `tools/fairy-discovery`, a beta-world developer tool, with a travel-log
  readout.
- Unit tests, an end-to-end test against a strict fake game API, and CI.

### Fixed

- "Not discovered yet" showed discovered rings. On the beta client,
  `List:Clear()` followed by `Add()` left old rows in the list, so the list is
  now refilled with `List:SetEntries`.
- The plugin didn't load on the October 22nd, 2026 beta client, which rejects
  empty `"requiredDependencies": []` lists in `plugin.json`.
