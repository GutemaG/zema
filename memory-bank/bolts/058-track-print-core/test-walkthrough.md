---
stage: test
bolt: 058-track-print-core
created: 2026-11-19T19:00:00Z
---

## Test Walkthrough: tag clean-up

### Tests

`packages/zema_core/test/lyrics/track_tags_test.dart` (13 tests):

- `cleanTag` / `cleanFileName`:
  - Removes `[@…]`, `CD N TRACK N (128)`, YouTube IDs, `@channel` and `_`.
  - Keeps ordinary last words.
  - Drops leading numbers from file names only, so the tag "7 Days" is kept.
- `isJunkTag`: placeholders and `Track 01` count as junk; real titles don't.
- `matchTitle` / `matchArtist`:
  - The file name is used for a junk tag and when there are no tags.
  - "Track NN" gives an empty title.
  - Channel, junk and title-again artists count as unknown.
- `SongMatcher`:
  - A "Track 01" tag links by its file name.
  - The artist in the file name or the title breaks a tie.
  - A tie stays unlinked when nothing breaks it.

### Bugs found

1. **`@channel` handles were split.** `_` turned into a space first, which left
   `Maryam2127` behind. Channels are now removed first.
2. **`@\S+` also ate the `]` of `[@ETHIOALBUMS]`.** Handles are now letters, digits,
   `_` and `.`.

### Results

- `zema_core`: 366 tests pass; `dart analyze` is clean.
- `apps/mobile`: lyrics, detection, home and library tests pass (362);
  `flutter analyze` is clean.
- Owner's 98 files (scratch script, old vs new): 67 right → right, 14 missed → right,
  17 none → none, 0 worse.
