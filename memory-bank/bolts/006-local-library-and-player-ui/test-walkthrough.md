---
stage: test
bolt: 006-local-library-and-player-ui
created: 2026-10-26T08:19:38Z
---

## Test Report: local-library-and-player-ui (bolt 3 of 5)

### Summary

- **Tests**: 438/438 passed:
  - 382 in `apps/mobile`, up from 279
  - 56 in `packages/zema_core`, up from 49
  - The on-device scroll test from bolt 005 wasn't rerun; this bolt didn't change the Tracks list.
- **Coverage**: 93.7% of lines in `apps/mobile/lib/` excluding generated code (2717/2901), up from 92.0%; 95.2% without Drift's table declarations. Most of the rest is still `JustAudioBackend`, the real plugin wrapper.
- **CI sequence run locally**: format check, `flutter analyze`, `flutter test`, `dart analyze`, `dart test` all exit 0; generated localizations in sync. The iOS simulator build compiles.

### Test Files

- [x] `packages/zema_core/test/player/play_queue_test.dart` - entry keys (distinct for a song queued twice, kept when moved); restore in place, before the current song, while shuffled (original order too), into a shorter queue; no restore twice or after a new queue loads
- [x] `apps/mobile/test/features/player/data/zema_audio_handler_test.dart` - queue keys; move keeps the current song without reloading; remove and restore; current can't be removed; clear upcoming keeps playing
- [x] `apps/mobile/test/features/player/data/sleep_timer_test.dart` (fake clock):
  - end time and time left
  - a 5 s fade in falling steps to silence, then a pause at full volume
  - keeps counting while paused; ending while paused only clears the timer
  - cancel during the fade restores the volume and keeps playing
  - pause during the fade restores the volume at once and stops the fade
  - a new timer replaces the old one; cancel and stop turn it off
  - end of current song: next song ready and paused, or stop at the start of the last song
- [x] `apps/mobile/test/features/library/application/folder_tree_test.dart` - phone, second profile, SD card and other roots; breadcrumb paths; folders by name; contents with counts of everything below; a folder holding only subfolders; all songs under a folder; a name prefix is not a parent; empty library
- [x] `apps/mobile/test/features/library/application/album_grouping_test.dart`:
  - track order, total duration, most common year (latest on a tie), no year
  - album artist, a single shared artist, various artists, unknown artist
  - "Unknown album"; the same name by different album artists is two albums
  - album ids round-trip through route parameters (Ethiopic, `&`, `/`)
  - three sorts both ways, with unknowns last
- [x] `apps/mobile/test/features/library/application/artist_grouping_test.dart` - names as written with unknown last; songs by title; albums newest first; avatar song with and without a named album; empty library
- [x] `apps/mobile/test/features/library/presentation/folders_test.dart` - list with count and path; C07; subfolders above songs; Play all covers everything below; a row plays the folder from there; breadcrumb and back; short breadcrumb starts on the left; hide removes songs everywhere, then Undo; Undo times out; missing folder C07; Ethiopic line height; 1.3× light and dark
- [x] `apps/mobile/test/features/library/presentation/albums_test.dart` - grid with two columns on a phone and more when wide; Various artists, album artist and Unknown album tiles; year sort saved; saved sort used at launch; album details and numbered songs; Play and row taps; Unknown album page; missing album C07; empty C07; 1.3× light and dark; total-duration text
- [x] `apps/mobile/test/features/library/presentation/artists_test.dart` - list with counts, unknown last; artist page with albums and songs; Play; album cover opens the album; Unknown artist page; missing artist C07; empty C07; 1.3× light and dark
- [x] `apps/mobile/test/features/player/presentation/queue_sheet_test.dart` - current highlighted and earlier songs dimmed; drag reorders; swipe and Undo; Undo shows on the sheet and times out; current can't be swiped; screen-reader remove only on upcoming songs; Clear queue (then disabled); tap plays; shuffled order; 1,000 songs open at the current one; 1.3×
- [x] `apps/mobile/test/features/player/presentation/sleep_timer_sheet_test.dart` - options; a preset starts the timer and Now Playing counts down; time left and Cancel in the sheet; end of song in both places; custom range (empty, 0 and 181 rejected with the message; 45 saved); digits only; 1.3× light and dark with a timer running
- [x] `apps/mobile/test/app/theme/zema_theme_test.dart` - snackbars use the opposite brightness with text and action at 4.5:1 or more; text buttons use `accentText` at 4.5:1 or more (all palettes, both brightnesses)
- [x] `apps/mobile/test/features/library/presentation/tracks_view_test.dart` - "Coming soon" check moved to Favorites
- [x] `apps/mobile/test/helpers/fake_player.dart`, `apps/mobile/test/helpers/fake_library.dart` - volume history; album artist, track number and year on test files

### Acceptance Criteria Validation

Story 009: Queue sheet
- ✅ **Queue button opens C02, current highlighted, upcoming below**: tests; emulator
- ✅ **Dragging changes the play order**: test; emulator
- ✅ **Swipe removes with Undo; current can't be removed**: tests. Removal checked on the emulator; Undo only in tests (see Notes).
- ✅ **"Clear queue" removes everything after the current song**: test
- ✅ **Tapping a row plays it**: test
- ✅ **Shuffled order when shuffle is on**: test
- ✅ **1,000-song queue opens at the current song**: test

Story 010: Sleep timer
- ✅ **15 / 30 / 45 / 60, end of song, custom 1–180**: tests; emulator
- ✅ **Time left in C05 and on S08; cancel**: tests; emulator (countdown on S08)
- ✅ **5 s fade, then pause; normal volume for the next play**: fake-clock tests (each volume step); emulator (paused before the song's end)
- ✅ **End of current song**: tests
- ✅ **Works with the screen off**: emulator (1-minute timer, screen off, paused at 40.7 s of a 48 s song)
- ✅ **Pausing keeps it counting; out-of-range custom disables Save with a message**: tests; emulator (200 rejected)
- ✅ **Timer logic tested with a fake clock**: `sleep_timer_test.dart`

Story 011: Folders
- ✅ **Every folder with visible songs, with name, count and path**: tests; emulator
- ✅ **S11a: breadcrumb, subfolders first with counts below, songs, Play all / Shuffle**: tests; emulator
- ✅ **Breadcrumb segment opens that folder**: tests; emulator
- ✅ **Hide removes songs everywhere, with Undo**: tests. Hiding checked on the emulator; Undo became visible only after the theme fix, so it's checked in tests.
- ✅ **No folders → C07; Ethiopic names keep the Ethiopic line height**: tests; emulator (መዝሙር)

Story 012: Albums
- ✅ **Grid with cover, name, artist; sort by name / artist / year; 2 columns on phones**: tests; emulator
- ✅ **S12a details, numbered songs, Play / Shuffle**: tests; emulator
- ✅ **Missing cover → themed placeholder**: emulator (none of the test files have art)
- ✅ **Unknown album; album artist or Various artists**: tests; emulator (Various artists)

Story 013: Artists
- ✅ **List with avatar and song count**: tests
- ✅ **S13a: albums and songs, Play / Shuffle**: tests
- ✅ **Unknown artist**: tests
- Not checked on the emulator (see Notes).

Quality
- ✅ **Analyze, format, all tests; 1.3× in light and dark without overflow**
- ✅ **Still builds for iOS**

### Issues Found

- **Countdown read one second short.** A new 30-minute timer showed 29:59 once the sheet's closing animation had run. The countdown now rounds up: 30:00 at the start, and 0:00 only at the very end.
- **Test-side issues:**
  - On narrow screens and at 1.3× text, the Albums and Artists tabs start partly off-screen in the scrolling tab bar. Tests scroll the tab into view before tapping it.
  - On the default 800×600 test screen, rows lower on the album and artist pages aren't built. Those tests use a taller screen.
  - One expectation was wrong: sorting albums by artist puts "Unknown album" first when its only artist is "Mahlet". The app was right.

Found during the implement stage and already fixed (see the implementation walkthrough): album tile overflow, invisible and never-ending Undo snackbars, the queue's Undo hidden behind the sheet, gold text buttons, the right-aligned short breadcrumb.

### Notes

- **Mutation checks:** each of these makes a test fail:
  - not moving the current index when restoring before it
  - not restoring the volume after the fade
  - not pausing at the end of the song
  - not stopping the fade when paused
  - counting only direct songs in subfolders
  - ignoring the album artist
  - Undo snackbars that persist
  - the queue's Undo sent to the page behind the sheet
  - rounding the countdown down
  - the right-aligned breadcrumb
  - snackbar actions without the inverse color

  The pause-during-fade check failed to catch its mutation at first, because the fade finishing later leaves the same end state. The test now checks right after the pause.
- **Emulator: someone else was using it.** Twice the app changed without input from me:
  - 10:50: a library shuffle was started, paused and skipped.
  - 11:17: the app was opened from System UI, Now Playing was opened from the mini player, and a 15-minute sleep timer was set.

  Another adb client (likely Android Studio) was polling the emulator the whole time. Its window sends taps outside adb. To avoid getting in the way, I didn't check these on the emulator; they are covered by widget tests:
  - the queue Undo
  - the text-button color
  - the short-breadcrumb alignment
  - the Artists screens

  A 15-minute sleep timer set from that session may still be running on the emulator.
- **Real phone, still open from bolts 004 and 005:** scrolling 1,000 tracks, 30 minutes screen-off with battery saver, the 1,000-file scan time.
