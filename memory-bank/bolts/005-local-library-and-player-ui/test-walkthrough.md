---
stage: test
bolt: 005-local-library-and-player-ui
created: 2026-10-24T21:19:31Z
---

## Test Report: local-library-and-player-ui (bolt 2 of 5)

### Summary

- **Tests**: 329/329 passed:
  - 279 in `apps/mobile`, up from 206
  - 49 in `packages/zema_core`, up from 21
  - 1 on-device integration test (scrolling 1,000 tracks, profile mode)
- **Coverage**: 92.0% of lines in `apps/mobile/lib/` excluding generated code
  (1722/1871); 94.4% without Drift's table declarations. Nearly all the rest is
  `JustAudioBackend` (the real plugin wrapper, exercised on the emulator) and `main.dart`;
  without those, 97.1%.
- **CI sequence run locally**: format check, `flutter analyze`, `flutter test`,
  `dart analyze`, `dart test` all exit 0; generated localizations in sync. The iOS
  simulator build compiles.

### Test Files

- [x] `packages/zema_core/test/player/play_queue_test.dart` - load and start index, next/previous with the 3 s rule, end-of-track for repeat off / all / one (including a queue of one), shuffle keeps the current track and turning it off restores order, insert next, add, the same song queued twice, remove (current can't be removed), move, clear upcoming, jump
- [x] `apps/mobile/test/features/player/data/zema_audio_handler_test.dart` - empty state; play from an index; media item (ID, art URI, `loadThumbnailUri: 'true'`) and playback state for the system; pause/play; next keeps the play state and stops at the end; previous restart vs back; advance at track end; stop at queue end; repeat all and one; shuffle on/off; shuffled start; skip an unplayable file and report it; clear the queue when nothing plays; try each file once around a repeating queue; restore paused at position; play after the queue finished; queue item jump; reported duration; stop
- [x] `apps/mobile/test/features/player/data/player_persistence_test.dart` - nothing saved; round-trip by Zema ID; broken values; empty queue
- [x] `apps/mobile/test/features/player/application/player_session_test.dart` - restore paused at the saved position; deleted tracks dropped and the next one used; nothing restored when all are gone; save on pause; save every 10 s while playing (fake time); the same unplayable song reported every time
- [x] `apps/mobile/test/features/player/presentation/player_screens_test.dart` - mini player hidden when empty, on every tab, play/pause and next, one labeled button, progress; opening and closing Now Playing; Now Playing content, shuffle and repeat cycling, previous/next, seek label follows the drag and seeks on release, seek bar read as one node "0:30 of 1:00", swipe down closes, accent vs gold progress, 1.3× on 320 dp in light and dark, skipped-song snackbar
- [x] `apps/mobile/test/features/library/application/tracks_query_test.dart` - search on title/artist/album (Ethiopic too); five sorts both ways; unknown artist/album last in both directions; stable ties; Latin, Ethiopic-family and `#` initials; section starts
- [x] `apps/mobile/test/features/library/application/artwork_cache_test.dart` - one load per image, shared in-flight loads, no-art and failures remembered, least-recently-used eviction
- [x] `apps/mobile/test/features/library/presentation/tracks_view_test.dart` - top tabs and placeholders; default title sort with alphabet strip; search and clear; sort change applied and saved; saved sort used at launch; tapping a row plays the visible list from it and highlights it; Play and Shuffle; strip jump; strip drag; 1.3× rows in light and dark
- [x] `apps/mobile/test/features/library/presentation/library_screen_test.dart` - updated for the "artist · duration" row text
- [x] `apps/mobile/integration_test/tracks_scroll_test.dart` + `test_driver/perf_driver.dart` - real app, 1,010 tracks, 12 flings, frame timings via `watchPerformance`
- [x] `apps/mobile/test/helpers/fake_player.dart` - fake backend (asynchronous events, like `just_audio`) and handler overrides

### Acceptance Criteria Validation

Story 005: Library tab and Tracks
- ✅ **Top tabs, Tracks first, tab kept**: tests; emulator
- ✅ **Count, rows with art or placeholder, artist · duration**: tests; emulator
- ✅ **Search on title/artist/album**: tests; emulator ("0020" → 1 song). Filtering runs over the in-memory list.
- ✅ **Five sorts, both directions, remembered**: tests
- ✅ **Alphabet strip with Latin, Ethiopic and `#`**: tests; emulator (A B K T U ሰ ቀ አ)
- ✅ **Tap plays from that row; Play and Shuffle play the visible list**: tests; emulator
- ✅ **C07 for no music and for no results**: tests; emulator
- ✅ **1.3×, light/dark, no overflow**: tests
- ⏳ **No frames over 16 ms scrolling 1,000 tracks**:
  - Building frames is well within budget: 90th percentile 1.2–5.2 ms over five profile runs.
  - Rasterizing on the emulator varies from run to run: 5.6–15.1 ms average, 15.9–29.7 ms at the 90th percentile, 54–149 of ~450–560 frames over budget.
  - The first runs used SwiftShader (CPU rendering) and were discarded. The emulator was then restarted with the Mac's GPU (`-gpu host`).
  - A real mid-range phone is needed to settle this.

Story 006: Playback engine
- ✅ **Audio starts in under 1 s**: 211–251 ms from tap to playing (emulator, debug)
- ✅ **Play, pause, seek, next, previous (3 s rule)**: handler and queue tests; emulator
- ✅ **Shuffle and repeat**: queue, handler and screen tests; emulator (repeat-one and advance at track end)
- ✅ **Unplayable file skipped with a snackbar**: tests; emulator (corrupted file)
- ✅ **Last queue restored paused; deleted tracks dropped**: session tests; emulator
- ✅ **`playerStateProvider`, `positionProvider`, `currentTrackProvider`**: used by the tests and screens
- ✅ **Queue, shuffle, repeat and previous logic unit-tested**

Story 007: Mini player and Now Playing
- ✅ **Mini player on every tab while loaded, hidden otherwise**: tests; emulator
- ✅ **Tap opens Now Playing; swipe down or back closes**: tests; emulator
- ✅ **Controls, seek bar with times, "No lyrics yet"**: tests; emulator
- ✅ **Seek label follows the drag, seeks on release**: test
- ✅ **Tokens only; accent for thin progress in light mode; light/dark**: tests
- ✅ **Labels; seek bar read as position of duration**: tests

Story 008: Notification, lock screen, headset
- ✅ **Background and screen-off playback; notification shows title, artist, controls and seek**: emulator (45 s screen-off with two track changes; notification screenshot)
- ✅ **Lock-screen controls**: same media session (`dumpsys media_session`)
- ✅ **Headset buttons**: emulator (`media_session dispatch` next / previous / play / pause / play-pause, and `KEYCODE_MEDIA_PLAY_PAUSE`)
- ✅ **Dismissible when paused (service leaves the foreground)**: emulator (`dumpsys activity services`)
- ✅ **Calls / focus loss pause; unplugging pauses**: built on `just_audio`'s interruption handling and `audio_session`'s unplug events. Not triggered on the emulator.
- ⏳ **30 min screen-off with battery saver on a real phone**: open (no phone)

### Issues Found

- **Wrong value type for the notification-art flag**: `loadThumbnailUri: true` made `audio_service` read the audio file as an image. Fixed: `'true'`.
- **Repeated failures went unreported**: the same song failing twice was reported once (Riverpod skips equal values). Fixed with a distinct event per skip; a test now covers it.
- **Name clash with Flutter**: Flutter 3.47's `RepeatMode` collided with ours. Renamed to `QueueRepeat`.
- **Overflow on short screens**: the scan-in-progress view overflowed on a 260 px screen. It now scrolls.
- **Seek bar heard as two items**: the label and the slider were separate screen-reader nodes. They are merged now, and the slider reads "0:30 of 1:00".
- **Test-side issues**:
  - The fake backend's synchronous streams re-entered; it's now asynchronous like `just_audio`.
  - `flutter drive` needs `--no-dds` for `watchPerformance`.
  - `flutter drive` uninstalls the app, so the scroll test uses a prebuilt APK, installed and granted access first.
- **Tried for scrolling, no measurable change**: drawing art placeholders with a rounded decoration instead of a clip didn't change emulator raster times. It's kept, since it is never more work.

### Notes

- **Mutation checks**: each of these makes a test fail:
  - removing queue clearing
  - removing save-on-pause
  - gold progress in light mode
  - next always playing
  - unknown artist not last when sorting descending
  - de-duplicating repeated skip reports
- **Running the scroll test**:
  1. `flutter build apk --profile -t integration_test/tracks_scroll_test.dart`
  2. `adb install -r …/app-profile.apk` and `adb shell pm grant com.zemaapp.zema android.permission.READ_MEDIA_AUDIO`
  3. `flutter drive --profile --no-dds --use-application-binary=…/app-profile.apk --driver=test_driver/perf_driver.dart --target=integration_test/tracks_scroll_test.dart`
- The emulator is now running with `-gpu host`, and the profile test APK is installed on it. Use `flutter run` for the debug app again.
