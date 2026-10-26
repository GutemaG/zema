---
stage: test
bolt: 014-lyrics-engine-and-display-ui
created: 2026-10-26T19:16:23Z
---

## Test Report: lyrics-engine-and-display-ui (bolt 6 of 9)

### Summary

- **Tests**: 778/778 passed:
  - 174 in `packages/zema_core`, up from 164
  - 604 in `apps/mobile`, up from 589
- **Coverage**:
  - `lyrics_links_dao.dart`: 23/23
  - `match_lyrics_sheet.dart`: 63/66
  - `lyrics_links.dart`: 31/35
  - `lyrics_links_repository.dart`: 11/12
- **CI sequence run locally**: format check, `dart analyze`, `dart test`, `flutter analyze` and `flutter test` all exit 0. The iOS simulator build compiles.
- **Planted bugs**: all 3 were caught.
  - Lowering the auto-link threshold to 0.5 failed the matching tests.
  - Letting automatic matching replace manual links failed the DAO test.
  - Inverting the menu's "linked" check failed the widget tests.
- **Emulator** (implementation stage):
  - The database upgraded from v1 to v2 with its data kept.
  - Only the three sample tracks linked automatically.
  - Change, Unlink and the picker work.

### Test Files

- [x] `packages/zema_core/test/lyrics/track_matching_test.dart`: 10 tests
  - title and transliteration matches, with title noise ignored
  - the threshold, the artist bonus, and ties giving no link
- [x] `apps/mobile/test/app/database/lyrics_links_dao_test.dart`: 6 tests
  - watch, `setManual` and `replaceAutomatic`
  - manual links and "no lyrics" are never replaced
  - links are removed along with their track
- [x] `apps/mobile/test/app/database/zema/migration_test.dart`
  - v1 → v2 schema check
  - data integrity across the upgrade
- [x] `apps/mobile/test/features/lyrics/presentation/lyrics_links_test.dart`: 7 widget tests
  - automatic links, and Change/Unlink shown for a linked track
  - a manual pick with its snackbar
  - picker search, with the linked song checked
  - manual links and Unlink both survive a rescan
  - the picker at 1.3× text in light and dark
- [x] `song_menu_test.dart`: updated for the lyrics items

### Test Helpers

- New: `test/helpers/fake_lyrics.dart` (`DiskAssetBundle`)
  - App tests read the bundled lyrics from disk; real asset loading stalls under the test clock.
  - `pumpZemaApp` uses it by default, with a fresh repository for each test.

### Notes

- In the app, the picker reuses the Library search hint text.
- The mini player overlaps the bottom of the picker sheet. Both are cosmetic; they will be revisited in bolt 015.
