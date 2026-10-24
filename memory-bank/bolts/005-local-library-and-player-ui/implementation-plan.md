---
stage: plan
bolt: 005-local-library-and-player-ui
created: 2026-10-24T20:12:00Z
---

## Implementation Plan: local-library-and-player-ui (bolt 2 of 5)

### Objective

Play a song end to end:
- the Library tab with the real Tracks screen (search, sort, fast-scroll)
- the playback engine with shuffle and repeat
- the mini player and Now Playing
- background playback with the media notification, lock screen and headset buttons

Stories: 005-library-tab-and-tracks, 006-playback-engine,
007-mini-player-and-now-playing, 008-media-notification.

### Deliverables

**1. Library tab and Tracks (story 005)**, in `lib/features/library/presentation/`
- `library_screen.dart`: the access gate from bolt 004 stays on top. Once access is granted, top tabs show: Tracks, Folders, Albums, Artists, Favorites, Playlists. The tabs after Tracks show C07 "Coming soon" until their stories land, and the selected tab is kept when switching bottom tabs.
- `tracks_view.dart`:
  - a count
  - a search field (title, artist, album; case-insensitive)
  - a sort menu: title, artist, album, date added or duration, ascending or descending; remembered in shared_preferences
  - Play and Shuffle buttons for the visible list
  - C07 for no results
  - the scan states from bolt 004
- `widgets/alphabet_scroller.dart`: a strip of the initials present in the list (A–Z, `#`, and Ethiopic base letters such as ሀ ለ ሐ), shown when sorted by title, artist or album. Dragging jumps the list. Rows have a fixed height, so a jump is instant even on 1,000 tracks.
- `lib/shared/widgets/track_row.dart` (art, title, artist · duration, highlighted when playing) and `track_art.dart` (lazy album art with a themed placeholder). Reused by every later list.
- `application/tracks_query.dart`:
  - search and sort as pure functions over the track list
  - the Ethiopic initial is the first letter's consonant family (ቁ → ቀ)
  - unknown artist or album sorts last
- `application/artwork_provider.dart`: art loaded through `LibraryScanner.loadArtwork`, kept in a small in-memory cache (about 200 images).

**2. Playback engine (story 006)**
- `packages/zema_core/lib/src/player/play_queue.dart`: pure-Dart queue logic.
  - load a list at an index, shuffled or not
  - next and previous (previous restarts the track when more than 3 s in)
  - what happens at the end of a track for repeat off / all / one
  - shuffle on keeps the current track first; off restores the original order after it
  - insert, move and remove, ready for the queue sheet in bolt 006
- `lib/features/player/data/audio_backend.dart`: a small interface over `just_audio` (set source, play, pause, seek, volume, streams) and its `just_audio` implementation. This lets the handler be tested with a fake.
- `lib/features/player/data/zema_audio_handler.dart`: the `audio_service` handler.
  - It owns the queue and the backend.
  - It publishes the playback state and current item to the system.
  - It plays one file at a time and moves on at the end of each track using `PlayQueue`.
  - An unplayable file is skipped and reported.
- `lib/features/player/data/player_persistence.dart`: saves the queue (track IDs), index and position on pause and every 10 s while playing. On launch it restores them, paused, and drops tracks that are gone.
- `lib/features/player/application/player_providers.dart`:
  - `playerStateProvider` (current track, playing, buffering, shuffle, repeat, queue)
  - `positionProvider`
  - `currentTrackProvider`
  - a `PlayerController` used by the UI: `playList`, toggle, seek, next, previous, shuffle, repeat
  - These are the providers intents 003 and 007 will read.
- `main.dart`: starts `AudioService` before `runApp`; restores the last queue.

**3. Mini player and Now Playing (story 007)**
- `lib/shared/widgets/mini_player.dart`:
  - sits above the nav bar on all tabs while something is loaded
  - shows art, title, artist, play/pause, next, and a thin progress line
  - tapping opens Now Playing
- `lib/features/player/presentation/now_playing_screen.dart`: route `/now-playing`, shown full screen above the tabs.
  - large art, title, artist
  - a seek bar with elapsed and remaining time; the label follows the drag and audio seeks on release
  - shuffle, previous, play/pause, next, repeat (off / all / one)
  - a lyrics area that says "No lyrics yet"
  - closes by swiping down or with back
  - Secondary buttons (queue, sleep timer, add to playlist, favorite) stay hidden until their stories land.
- Colors come only from `ZemaColors`; thin progress lines use `accent` in light mode (low-contrast gold rule). Every control is labeled for TalkBack, and the seek bar announces position and duration.

**4. Media notification, lock screen, headset (story 008)**
- `MainActivity` extends `AudioServiceActivity` and keeps the library channel.
- Manifest:
  - permissions `WAKE_LOCK`, `FOREGROUND_SERVICE`, `FOREGROUND_SERVICE_MEDIA_PLAYBACK`
  - the `audio_service` service with type `mediaPlayback`, and its media button receiver
- Notification:
  - art from the track's content URI, title, artist, previous / play-pause / next, and a seek bar
  - the channel name is localized from the phone's language
  - dismissing it while paused stops the service
- `audio_session`, music profile:
  - pause on calls and focus loss; resume after a short interruption
  - pause when headphones are unplugged
  - The "lower volume instead" option comes in story 021.

**5. Strings** in `app_en.arb`:
- top tab names, search hint, sort names, Play and Shuffle
- no-results text
- player control labels, repeat modes, "No lyrics yet"
- "Couldn't play this song"
- the notification channel name

### Dependencies

- `just_audio` ^0.10.6, `audio_service` ^0.18.19, `audio_session` ^0.2.4. Checked before planning: all three declare a namespace (compile SDK 35), and the debug APK builds with them on AGP 9.1.
- `rxdart` (already brought in by `audio_service`) becomes a direct dependency, because the handler publishes its state with it.
- Bolt 004's `LibraryScanner.loadArtwork`, `libraryTracksProvider` and `databaseProvider`.

### Technical Approach

- **One file at a time, our own queue.** `PlayQueue` decides what comes next, so shuffle, repeat, the queue sheet (006) and play counting (019) all rely on one tested class. Gapless playback (story 021, Should) would need `just_audio`'s playlist sources. That's decided in 021, and the queue logic stays the same either way.
- **The handler is the single source of truth.** The UI never touches `just_audio`. It sends commands through `PlayerController` and reads the providers fed by the handler's streams, so the notification, headset and app always agree.
- **Testability.** `PlayQueue` gets unit tests in `zema_core`. The handler is tested against a fake backend in `flutter test`. Widgets are tested with a fake `PlayerController`. Nothing in the tests touches audio plugins.
- **Restore** reads track IDs from the database, so a restored queue survives rescans and moves (Zema IDs).
- **Background.** `audio_service` runs the foreground service. The emulator checks drive it with `adb shell cmd media_session dispatch` and screenshots of the notification shade.
- **Performance.** Fixed row heights, lazy art with a cache, and search and sort on the in-memory list (1,000 tracks, well under 100 ms).
- **iOS** keeps compiling. The player works there in principle, but nothing can be played until iOS has a library, which is out of scope.

### Acceptance Criteria

Story 005
- [ ] Top tabs, Tracks first; selected tab kept across bottom-tab switches
- [ ] Count; rows with art (or placeholder), title, artist · duration
- [ ] Search on title/artist/album within 100 ms on 1,000 tracks
- [ ] Five sort fields, both directions, remembered across restarts
- [ ] Alphabet strip for title/artist/album sorts, Latin and Ethiopic initials; `#` for digits and symbols
- [ ] Tap plays the filtered, sorted list from that row; Play / Shuffle play the visible list
- [ ] C07 for no music and for no results
- [ ] No frames over 16 ms scrolling 1,000 tracks (profile, emulator); 1.3× text, light/dark, both palettes without overflow

Story 006
- [ ] Audio starts in under 1 s after a tap (emulator, logged)
- [ ] Play, pause, seek, next, previous (restart after 3 s) act immediately
- [ ] Shuffle keeps the current track and reshuffles the rest; off restores order
- [ ] Repeat off / all / one at the end of a track and of the queue
- [ ] Unplayable file skipped with a snackbar
- [ ] Last queue, track and position restored paused on launch; deleted tracks dropped
- [ ] State available from `playerStateProvider`, `positionProvider`, `currentTrackProvider`
- [ ] Queue, shuffle, repeat and previous logic unit-tested

Story 007
- [ ] Mini player above the nav bar on every tab while something is loaded; hidden otherwise
- [ ] Tap opens Now Playing; swipe down or back closes it
- [ ] S08 controls, seek bar with elapsed/remaining, "No lyrics yet"
- [ ] Seek label follows the drag; audio seeks on release
- [ ] Tokens only; accent for thin progress in light mode; light/dark × both palettes
- [ ] TalkBack labels on every control; seek bar announces position and duration

Story 008
- [ ] Music keeps playing in the background and with the screen off; notification shows art, title, artist, prev / play-pause / next, seek bar
- [ ] Lock-screen controls work
- [ ] Headset/Bluetooth media buttons work (emulated with `media_session dispatch`)
- [ ] Dismissing the notification while paused stops the service
- [ ] Calls / focus loss pause, short interruptions resume; unplugging pauses
- [ ] ⏳ 30 min screen-off with battery saver on a real phone (open if no phone)

Quality
- [ ] `flutter analyze`, `dart format`, all tests clean; app runs on the emulator and still builds for iOS
