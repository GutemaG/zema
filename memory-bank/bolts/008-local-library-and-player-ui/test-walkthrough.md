---
stage: test
bolt: 008-local-library-and-player-ui
created: 2026-10-26T12:48:29Z
---

## Test Report: local-library-and-player-ui (bolt 5 of 5)

### Summary

- **Tests**: 599/599 passed:
  - 532 in `apps/mobile`, up from 442
  - 67 in `packages/zema_core`, up from 62
- **Coverage**: 93.9% of lines in `apps/mobile/lib/` excluding generated code (4276/4552), down from 94.2%; 94.9% without Drift's table declarations. The drop is the audio backend's new code, which wraps `just_audio` directly and can only run on a device. New code that tests can reach is 89–100% covered; the DAO, play counter, selection and selection bar are at 100%.
- **CI sequence run locally**: format check, `flutter analyze`, `flutter test`, `dart analyze`, `dart test` all exit 0. The iOS simulator build compiles.
- **Emulator**: partly checked; the emulator was in use by someone else partway through (see Notes).

### Test Files

- [x] `packages/zema_core/test/player/play_queue_test.dart` - `upcoming`: next item without moving; end of queue with and without repeat all; repeat one; matches `trackCompleted` under shuffle; follows Play next and Clear
- [x] `apps/mobile/test/features/player/data/play_counter_test.dart` (fake clock):
  - counts once at 30 s
  - paused time doesn't count
  - pausing past 30 s counts at the pause
  - seeking back doesn't count again; a seek's jump isn't listening
  - short songs count at their full length or at their end
  - a long song reaching its end early doesn't count
  - next song and repeat one count again; a skip before 30 s doesn't
  - stop doesn't count
- [x] `apps/mobile/test/app/database/history_dao_test.dart`:
  - most played by count, ties to the latest
  - recently played distinct and latest first
  - dates stored with an offset compare by the instant (order and prune)
  - prune before a date
  - kept through a rescan with a missing file
  - the stream updates
- [x] `apps/mobile/test/app/database/library_dao_test.dart` - batch hide and unhide; hiding twice; hidden songs by title without missing files; hidden folders by path; the visible count matches the list
- [x] `apps/mobile/test/app/database/collections_dao_test.dart` - batch favorite keeps existing times; batch unfavorite
- [x] `apps/mobile/test/features/settings/data/settings_repository_test.dart` - new defaults; round trip and storage keys; unknown values fall back
- [x] `apps/mobile/test/features/settings/application/settings_controller_test.dart` - new setters update state and save once
- [x] `apps/mobile/test/features/player/data/zema_audio_handler_test.dart`:
  - counting plays through the handler: once at 30 s, paused time, repeat one, short song at its end
  - options reach the backend
  - gapless:
    - preload, and takeover without a load
    - a play counts across the takeover
    - no preload at the end or for repeat one; repeat all preloads the first song
    - "stop at end of song" clears the preload until cancelled
    - Play next, remove, move and clear update the preload
    - gapless off: no preload, one load per song; turning it on preloads at once
    - a stale preload falls back to the queue
- [x] `apps/mobile/test/features/library/application/play_history_test.dart`:
  - Recently added window (30 days to the minute) and order
  - hidden and too-short songs left out before the top 50
  - most and recently played order; an unhidden song returns
  - Recently added from the visible library
  - counted plays stored; year-old plays pruned at start
- [x] `apps/mobile/test/features/library/presentation/track_selection_test.dart`:
  - long-press starts selection with the count; taps toggle; the last one off ends it
  - Select all respects the search; with no search it selects every song
  - back and Close end selection without changes
  - Add to queue in list order (paused when nothing played)
  - Favorite then Unfavorite; a mix offers Favorite
  - Hide with Undo
  - Add to playlist skips songs already there; New playlist creates it with the songs; dismissing the sheet keeps the selection
  - a song hidden elsewhere leaves the selection
  - 1.3× light and dark
- [x] `apps/mobile/test/features/library/presentation/auto_playlists_test.dart`:
  - the section after user playlists with counts
  - Most played order, read-only page, song menu, Play
  - Recently played latest first and distinct; Recently added newest first
  - hiding from the menu removes the song
  - empty states; nothing added in 30 days; malformed link → C07
  - 1.3× light and dark
- [x] `apps/mobile/test/features/settings/presentation/library_playback_settings_test.dart`:
  - Library:
    - hidden folders and hidden songs with Unhide bringing songs back to Tracks; empty states
    - Rescan: progress, then "Found N songs" (too-short songs not counted); failure with Try again; no access opens the Library tab's permission flow without scanning
    - minimum length: options, applied with no rescan, saved, and used from the start
  - Playback:
    - defaults; sleep default saved
    - switches (row and switch) reach the player and are saved
    - Lower volume with the calls note reaches the player
    - saved values shown and applied after a restart
  - switch rows read their state to screen readers; tap targets labeled
  - 1.3× light and dark: Settings, a sheet, both hidden pages (a long Ethiopic folder name)
- [x] `apps/mobile/test/features/player/presentation/sleep_timer_sheet_test.dart` - nothing preselected by default; the saved default selected with a check and nothing started until tapped; end of song as the default
- [x] `apps/mobile/test/features/settings/presentation/settings_screen_test.dart`, `test/features/library/presentation/playlists_test.dart` - updated for the new sections and the auto playlists

### Acceptance Criteria Validation

Story 018: Track multi-select
- ✅ **Long-press starts selection with that row and a count**: selection tests
- ✅ **Taps toggle; Select all selects the visible list**: selection tests
- ✅ **Add to playlist / queue, Favorite, Hide apply to all, end selection, snackbar (Undo for hide)**: selection tests
- ✅ **Back ends selection without changes**: selection test

Story 019: Play history and auto playlists
- ✅ **30 s (or to the end if shorter) stores one event; no double count**: counter, handler and provider tests
- ✅ **Recently added (30 days), Most played (top 50), Recently played (last 50, newest first)**: provider and widget tests
- ✅ **Auto playlist page with Play / Shuffle, no reorder, remove or rename**: widget test
- ✅ **Kept through restart and rescan**: DAO rescan test; rows keyed by Zema ID
- ✅ **Events older than a year pruned at start**: provider test
- ✅ **Hidden and missing tracks left out**: provider and widget tests
- ✅ **Counting tested with a fake clock; queries with an in-memory database**: counter and DAO tests

Story 020: Library settings
- ✅ **Library section between General and About**: Settings test
- ✅ **Hidden folders / songs with Unhide; items come back everywhere**: Settings tests
- ✅ **Rescan shows progress and the number found**: Settings test
- ✅ **Ignore audio shorter than: off / 10 / 30 / 60 s, default 30, no rescan, persists**: Settings and repository tests
- ✅ **Rescan with no access starts the permission flow**: Settings test

Story 021: Playback settings
- ✅ **Playback section after Library**: Settings test; emulator
- ✅ **Sleep timer default preselected in C05**: sleep sheet tests
- ⚠️ **Pause on unplug (default on)**: setting reaches the player (tests). Unplugging a headset on a device is not checked.
- ⚠️ **Pause / Lower volume (default Pause); calls still pause**: setting reaches the player (tests). A real interruption is not checked; behavior comes from `audio_session` and `just_audio` (checked in their sources).
- ⚠️ **Gapless (Should, default on)**: preload and takeover tested with the fake backend. On the emulator a bug was found and fixed (see Issues); the fixed build's takeover has not been heard on a device yet.
- ✅ **Values kept after a restart**: Settings and repository tests

Quality
- ✅ **Analyze, format, all tests; 1.3× in light and dark without overflow**
- ✅ **Still builds for iOS**
- ⚠️ **Checked on the Android emulator**: partly (see Notes)

### Issues Found

- **Gapless skipped songs (found on the emulator).**
  - The app log showed "Advanced without a gap" about 70 ms after normal loads.
  - The backend took `just_audio`'s auto-advance discontinuity as the signal. `just_audio` reports one whenever the playing item changes without a seek, a new load included.
  - So each load moved the queue on by one song.
  - The backend now treats only reaching the preloaded second item as a takeover. Its playlist never holds more than two files and nothing seeks to the second, so this can't be confused with a load.
  - The fake backend can't reproduce this, so no unit test covers it. It needs a device check.
- **A 30 s timer in the first play counter** left a pending timer in 50 widget tests. The counter now checks on position updates instead.
- **Playback options didn't reach the player** when a test opened Settings directly: the provider that applies them lives in the app shell. In the app, Settings is always reached through the shell. Tests now go through Home, and the first options always reach the backend, even the defaults.
- **Test-side:** stream listeners use the clock of the zone they were created in, so handlers under a fake clock are built inside it. A failing widget test in these files can take minutes to tear down, so mutation runs target single tests.

### Notes

- **Mutation checks:** each of these makes a test fail:
  - a play counting twice
  - paused time counting
  - most played least first
  - the top 50 taken before hiding
  - preload kept for "stop at end of song"
  - a gapless takeover reloading
  - Select all ignoring the search
  - back not ending selection
  - the minimum length setting ignored
  - C05 ignoring the default
  - old plays never pruned
  - the unplug switch not reaching the player
- **Emulator:**
  - **Settings:** checked before the emulator was taken over. Library sits between General and About, Playback after Library. Values show (0 hidden, 30 s, None, Pause) and the switches are on.
  - **Rescan:** synced 1,009 files in 62 ms.
  - **Not checked**, because the emulator was in use and taps landed on other screens:
    - multi-select
    - auto playlists after real plays
    - the hidden pages
    - minimum length Off
    - the gapless takeover by ear with the fixed build
- **Intent "Done when":**
  - **Restart persistence:** covered by tests.
  - **Background playback:** checked on the emulator in bolt 005.
  - **Real phone, still open:** the 1,000-track scan under 5 s, 60 fps scrolling, 30 min screen-off with battery saver, headset unplug, and a real interruption.
