---
stage: test
bolt: 009-lyrics-engine-and-display-ui
created: 2026-10-26T14:11:27Z
---

## Test Report: lyrics-engine-and-display-ui (bolt 1 of 9)

### Summary

- **Tests**: 620/620 passed:
  - 553 in `apps/mobile`, up from 532
  - 67 in `packages/zema_core`, unchanged
- **Coverage**: 94.3% of lines in `apps/mobile/lib/` excluding generated code (4514/4789), up from 93.9%. All new Home files are at 100%; `library_access_gate.dart` 97%, `library_screen.dart` 100%.
- **CI sequence run locally**: format check, `flutter analyze`, `flutter test`, `dart analyze`, `dart test` all exit 0. The iOS simulator build compiles.
- **Emulator**: checked with the tested build (see Notes).

### Test Files

- [x] `apps/mobile/test/features/home/presentation/home_screen_test.dart` (new, 21 tests):
  - sections in order with no "Coming soon"; empty sections hidden; rows update without a restart; Search button opens the Search tab
  - quick actions: Shuffle all plays the whole library shuffled; disabled (no tap handler) while the first scan has found nothing; Favorites opens Library on Favorites, also after moving to another tab; Playlists; Recently added
  - Continue listening: "Resume from 1:23", resume without reloading, hidden while playing; tapping the card resumes; hidden once the song is hidden
  - rows: Recently played latest first, plays the row from the tapped song, at most 10, See all; a playlist card opens the playlist and See all opens the Playlists tab after Library was opened off screen
  - states: permission explanation, then Home after allowing; empty library with Rescan; failed scan with Try again
  - 1.3× on a 320 × 640 phone in light and dark with a long Ethiopic playlist name; cards read as one label (title and artist)
- [x] `apps/mobile/test/helpers/fake_library.dart` - `GatedLibraryScanner` moved here from the settings test so both can hold a scan
- [x] `apps/mobile/test/app/app_shell_test.dart`, `test/app/l10n/localizations_test.dart`, `test/features/settings/presentation/library_playback_settings_test.dart` - updated for Home's content and the shared scanner

### Acceptance Criteria Validation

Story 001: Home header and quick actions
- ✅ **Search shortcut and Settings in the header**: tests (Search); Settings unchanged
- ✅ **Quick actions play or open the right thing**: tests; emulator
- ✅ **No audio access shows the C07 permission state**: test
- ✅ **Empty library shows C07 with Rescan**: test
- ✅ **1.3× light and dark without overflow**: test

Story 002: Home continue listening and recent rows
- ✅ **Continue listening card resumes from the position**: test; emulator shows "Resume from 0:11"
- ✅ **Recently played row (max 10), plays from the tapped song, See all**: tests
- ✅ **Your playlists row opens playlists**: test; emulator
- ✅ **Sections with nothing hide**: test
- ✅ **Rows update without a restart**: test

### Issues Found

- **Crash when Home asked for a Library tab while Library was off screen** (found by a test). If the Library tab had been built but not shown since, for example after opening a playlist from Home, switching its tab bar threw a null check: an off-screen tab bar has no size to scroll. The switch now waits for the next frame, when Library is shown. A test covers it, and the emulator confirms it.
- **Continue listening showed 0:00 in tests**: the card starts listening for positions only once the song is paused, and a paused player sends none. It now reads the player's current position until an update comes.
- **A weak test** (found by a planted bug): "Shuffle all disabled" only checked that nothing played, which is also true with no songs when the tile is enabled. It now checks that the tile has no tap handler.

### Notes

- **Planted bugs**: each of these makes a test fail:
  - the card shown while playing
  - no 10-song limit
  - the tab request ignored
  - Shuffle all enabled with no songs
  - the card shown for a hidden song
  - the row always playing from its first song
- **Emulator** (tested build):
  - Home shows all sections with the existing library and plays
  - Favorites and Playlists open the right Library tab
  - opening a playlist from Home, returning, then See all opens the Playlists tab with no error in the log
  - a debug cold start shows a black screen for about 15 s before Home; release builds aren't affected. Home's "on screen in under 1 s" goal needs a release build on a phone.
- **Navigation**: pages opened from Home (Recently added, a playlist) live in the Library tab, so Back returns to Library.
