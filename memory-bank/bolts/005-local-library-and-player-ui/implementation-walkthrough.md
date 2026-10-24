---
stage: implement
bolt: 005-local-library-and-player-ui
created: 2026-10-24T20:54:50Z
---

## Implementation Walkthrough: local-library-and-player-ui (bolt 2 of 5)

### Summary

Zema now plays music. The Library tab has top tabs with a real Tracks screen
(search, remembered sort, Latin and Ethiopic alphabet strip, Play and Shuffle). Tapping
a song plays the list from there through an `audio_service` handler over `just_audio`.
A mini player sits above the navigation on every tab and opens a full Now Playing
screen. Playback continues in the background with a media notification, lock-screen
and headset controls, and the queue comes back paused after a restart.

### Structure Overview

- **`PlayQueue` in `zema_core`** decides what plays next: shuffle, repeat, previous,
  insert, move, remove.
- **`ZemaAudioHandler`** owns the queue and an `AudioBackend` (a thin interface over
  `just_audio`). It plays one file at a time and publishes state two ways: to the app as
  `PlayerSnapshot` and position streams, and to Android through `audio_service`.
- **Riverpod providers and a `PlayerController`** are the only way the UI reads or
  drives the player.
- **A player session provider**, kept alive by the shell, restores and autosaves the
  queue.

### Completed Work

**Library tab and Tracks (story 005)**
- [x] `lib/features/library/presentation/library_screen.dart` - access gate, then top tabs (Tracks plus five "Coming soon" tabs)
- [x] `lib/features/library/presentation/tracks_view.dart` - search field with clear, count, sort menu, Shuffle and Play, fixed-height list, alphabet strip, scan and no-results states
- [x] `lib/features/library/presentation/widgets/track_row.dart` - art, title, artist · duration; the current song is highlighted
- [x] `lib/features/library/presentation/widgets/track_art.dart` - lazy album art; `tile` square with the first letter until art loads or when there is none
- [x] `lib/features/library/presentation/widgets/alphabet_scroller.dart` - strip of section initials; tap or drag to jump
- [x] `lib/features/library/application/tracks_query.dart` - search, stable sort (unknown artist or album last), Ethiopic consonant-family initials, section starts
- [x] `lib/features/library/application/track_sort_provider.dart` - sort remembered in shared_preferences
- [x] `lib/features/library/application/artwork_provider.dart` - art through the scanner with a 200-image in-memory cache
- [x] `lib/shared/format_duration.dart` - `m:ss` / `h:mm:ss`

**Playback engine (story 006)**
- [x] `packages/zema_core/lib/src/player/play_queue.dart` - queue logic; `QueueRepeat` off / all / one
- [x] `lib/features/player/data/audio_backend.dart` - `AudioBackend` interface and the `just_audio` implementation; `audio_session` music setup; unplugging headphones pauses
- [x] `lib/features/player/data/zema_audio_handler.dart` - the `audio_service` handler: play, pause, seek, next, previous (restart after 3 s), shuffle, repeat, end-of-track handling, skipping unplayable files (the queue is cleared if nothing plays), state for the app and the system
- [x] `lib/features/player/data/player_snapshot.dart` - what the UI reads about the player
- [x] `lib/features/player/data/player_persistence.dart` - queue (Zema IDs), index, position and repeat in shared_preferences
- [x] `lib/features/player/application/player_providers.dart` - `playerStateProvider`, `positionProvider`, `currentTrackProvider`, `unplayableTrackProvider`, `PlayerController`, and the session provider that restores the queue paused and saves it on pause and every 10 s while playing
- [x] `lib/app/database/library_dao.dart` - `tracksByIds` for restoring a queue (missing files dropped)
- [x] `lib/main.dart` - starts `AudioService` before `runApp`; the notification channel name follows the app's language

**Mini player and Now Playing (story 007)**
- [x] `lib/features/player/presentation/mini_player.dart` - C01 on `surface`: progress line, art, title, artist, play/pause, next; tap opens Now Playing; labeled for TalkBack
- [x] `lib/features/player/presentation/now_playing_screen.dart` - S08: close button, art (hero from the mini player), title, artist, "No lyrics yet", seek bar, shuffle / previous / play-pause / next / repeat; closes with the arrow, back or a swipe down
- [x] `lib/features/player/presentation/player_progress.dart` - progress line and seek bar; `accent` instead of gold for thin progress in light mode; the seek bar announces "position of duration"
- [x] `lib/app/router.dart`, `lib/app/routes.dart` - `/now-playing`, sliding up over the tabs
- [x] `lib/app/app_shell.dart` - mini player above the navigation; keeps the player session alive; snackbar "Couldn't play {title}"

**Notification, lock screen, headset (story 008)**
- [x] `android/.../MainActivity.kt` - extends `AudioServiceActivity`, keeps the library channel
- [x] `android/app/src/main/AndroidManifest.xml` - wake lock and media-playback foreground service permissions, the `audio_service` service (`mediaPlayback`) and media button receiver

**Strings and tests kept green**
- [x] `lib/l10n/app_en.arb` - 39 new strings (tabs, search, sort, player controls, repeat modes, notification channel, skip message)
- [x] `test/helpers/fake_player.dart` - fake audio backend and handler overrides
- [x] `test/helpers/pump_app.dart`, `test/app/app_shell_test.dart`, `test/app/zema_app_test.dart`, `test/features/library/presentation/library_screen_test.dart` - updated for the player and the new row text

### Key Decisions

- **Our own queue, one file at a time**: one tested class drives shuffle, repeat, the queue sheet (bolt 006) and play counting (bolt 008). Gapless playback (story 021) is decided there.
- **`QueueRepeat`, not `RepeatMode`**: Flutter 3.47 has its own `RepeatMode` (animations), which made every player screen ambiguous.
- **A restored queue starts with shuffle off**: only the play order is saved. Re-shuffling it on restore would change the order the user saw.
- **Clear the queue when nothing in it plays**: otherwise the mini player keeps showing a song that can't play.
- **Each skip is a new event object**: Riverpod ignores updates that compare equal, so the same song failing twice would only be reported once.
- **Row and art widgets live in the library feature**, not `lib/shared/`. They need the library's artwork provider, and features may use each other's presentation and application layers.
- **Notification art** uses the track's own content URI with `loadThumbnailUri: 'true'`. The value must be a string; a boolean made `audio_service` fall back to reading the audio file as an image.

### Deviations from Plan

- Track row and art are in `lib/features/library/presentation/widgets/`, and the mini player is in `lib/features/player/presentation/`, instead of `lib/shared/widgets/` (see above).
- The scan-in-progress view now scrolls on very short screens. It overflowed in a 260 px-tall test.

### Dependencies Added

- [x] `just_audio` ^0.10.6 - playback
- [x] `audio_service` ^0.18.19 - background service, notification, lock screen, media buttons
- [x] `audio_session` ^0.2.4 - music audio session, unplug events
- [x] `rxdart` ^0.28.0 - the handler's state streams

### Developer Notes

- Emulator checks:
  - Tap → playing in 211–251 ms (debug).
  - Moving on at the end of a track works on screen and with the screen off.
  - Notification and lock screen show title, artist, prev / pause / next and seek.
  - `media_session dispatch` next / previous / play / pause / play-pause all work.
  - When paused, the service leaves the foreground, so the notification can be dismissed.
  - A corrupted file is skipped with "Couldn't play Bulk Track 0021".
  - The queue is restored paused after relaunch.
- `dumpsys media_session` can show the state one command behind; the handler's FINE / FINER log lines (debug builds only) are the reliable source.
- Early in the emulator session, a few blind coordinate taps landed on other screens, which first looked like spurious skips. Step-by-step runs with the handler log show correct behavior.
- iOS builds. Background audio on iOS would need `UIBackgroundModes: audio`; it's not added, since iOS has no library yet.
