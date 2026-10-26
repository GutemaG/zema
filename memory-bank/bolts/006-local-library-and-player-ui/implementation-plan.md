---
stage: plan
bolt: 006-local-library-and-player-ui
created: 2026-10-26T07:27:17Z
---

## Implementation Plan: local-library-and-player-ui (bolt 3 of 5)

### Objective

Finish the player's two sheets and add three browse tabs:
- the queue sheet (C02): reorder, remove with undo, clear
- the sleep timer sheet (C05): presets, end of song, custom, fade out
- Folders (S11 / S11a) with breadcrumb and hide
- Albums (S12 / S12a)
- Artists (S13 / S13a, Should)

Stories: 009-queue-sheet, 010-sleep-timer, 011-folders, 012-albums, 013-artists.

There are no mockups for these screens. They follow the design system and reuse the
patterns already used by Tracks and Now Playing.

### Deliverables

**1. Queue sheet (story 009)**
- `packages/zema_core/lib/src/player/play_queue.dart`:
  - a stable key for each queue entry, so a song queued twice gets two rows that can each be dragged and swiped
  - `removeAt` returns what was removed, and `restore(removal)` puts it back in the same place in both the shuffled and the original order (for undo)
- `zema_audio_handler.dart`: move, remove, restore and clear-upcoming commands that publish the new queue. Tapping a row uses the existing `skipToQueueItem`.
- `PlayerSnapshot` gains the entry keys; `PlayerController` gains `moveInQueue`, `removeFromQueue` (returns an undo action) and `clearUpcoming`.
- `lib/features/player/presentation/queue_sheet.dart`, a draggable bottom sheet:
  - a header with the song count and "Clear queue"
  - the whole queue in play order: earlier songs dimmed, the current one highlighted, then upcoming songs
  - opens scrolled to the current song (fixed row height, so this is instant for 1,000 songs)
  - drag handles to reorder; swipe a row away to remove it, with an undo snackbar
  - the current song can't be swiped away; tapping a row plays it
  - with shuffle on, the rows are in the shuffled order (the play order)

**2. Sleep timer (story 010)**
- The timer lives in the handler, so it keeps running with the screen off and the UI closed:
  - `setSleepTimer(duration)`, `sleepAtEndOfTrack()`, `cancelSleepTimer()`
  - the snapshot carries the timer state: the end time, or "end of song"
- When a timed timer ends:
  - the volume fades to zero over 5 s, then playback pauses and the volume goes back to normal for the next play
  - if the player is already paused, the timer just clears
  - pausing doesn't stop the countdown
  - cancelling during the fade restores the volume at once
- "End of current song": when the song ends, the queue moves to the next song and stays paused.
- Time is read through `package:clock`, so tests drive the timer and the fade with `fake_async`.
- `lib/features/player/presentation/sleep_timer_sheet.dart`:
  - 15, 30, 45 and 60 min, end of current song, and Custom (a dialog for 1–180 min; Save is disabled with a message when out of range)
  - while a timer runs, the sheet shows the remaining time and Cancel
- Now Playing: a secondary row under the transport controls with the sleep timer button (showing the remaining time when set) and the queue button. Bolt 007 adds favorite and add to playlist to this row.
- The default preselection from the Playback setting comes with story 021.

**3. Folders (story 011)**
- `lib/features/library/application/folder_tree.dart`, pure functions over the visible tracks:
  - the folders that directly contain songs, each with its count and its path relative to the storage root
  - a folder's subfolders (with the count of all songs below them) and its own songs
  - breadcrumb segments
  - The root `/storage/emulated/0` is shown as "Phone"; other volumes under `/storage/<id>` as "SD card".
- `presentation/folders_view.dart` (S11): the folder list (name, song count, path) with a menu holding Hide. Empty → C07.
- `presentation/folder_screen.dart` (S11a), route `/library/folder?path=…` inside the Library branch, so the nav bar and mini player stay:
  - a breadcrumb; tapping a segment opens that folder
  - subfolders first, then songs
  - Play all and Shuffle
- Hide: the folder's tracks disappear everywhere at once (the visible-tracks query already excludes hidden folders), with an Undo snackbar. Unhiding from Settings comes with story 020.

**4. Albums (story 012)**
- `application/album_grouping.dart`:
  - albums grouped by album name and album artist; tracks without an album go to "Unknown album"
  - Artist is the album artist; else the one artist all tracks share; else "Various artists"
  - Year is the year most of the tracks have
  - Tracks are ordered by track number, then title; the total duration is computed
  - sort by name, artist or year, both directions, unknowns last; remembered like the track sort
- `presentation/albums_view.dart` (S12): a grid of covers with album name and artist, 2 columns on phones (max tile width), and a sort menu. Empty → C07.
- `presentation/album_screen.dart` (S12a), route `/library/album?…`:
  - cover, name, artist, and "year · N songs · total duration"
  - Play and Shuffle
  - a numbered track list
- Missing covers use the theme's `tile` placeholder with the album's initial. `TrackArt` gains an optional placeholder letter.

**5. Artists (story 013, Should)**
- `application/artist_grouping.dart`: artists by the artist string as is, with "Unknown artist" for tracks without one. Each has its song count, its albums, and a cover track for the avatar.
- `presentation/artists_view.dart` (S13): rows with a round avatar (an album cover, or the initial) and a song count. Empty → C07.
- `presentation/artist_screen.dart` (S13a), route `/library/artist?…`:
  - their albums as a horizontal row of covers that open S12a
  - their songs, with Play and Shuffle

**6. Shared pieces**
- A `PlayShuffleBar` (count, Shuffle, Play) taken out of the Tracks header and reused by every detail screen.
- `PlayerController.shuffleList(tracks)`, so screens don't each pick a random start.
- The Library tabs show Folders, Albums and Artists; Favorites and Playlists stay "Coming soon" until bolt 007.

**7. Strings** in `app_en.arb`:
- queue: title, count, Clear queue, removed + Undo, the drag and remove labels
- sleep timer: options, custom dialog and its range message, remaining time, Cancel
- folders: Phone, SD card, Hide folder, "Folder hidden" + Undo, subfolder count
- albums: sort names, Various artists, the "year · songs · duration" line
- artists: song count and section titles

### Dependencies

- `clock` (direct dependency) and `fake_async` (dev): both are already in the lockfile through `flutter_test`, so the versions don't change.
- No new plugins.
- From bolts 004 and 005:
  - `libraryTracksProvider` (visible tracks)
  - `LibraryDao.hideFolder` / `unhideFolder`
  - `PlayQueue`, `ZemaAudioHandler`, `PlayerController`
  - `TrackRow`, `TrackArt`, `EmptyState`

### Technical Approach

- **Everything derives from the visible-tracks stream.** Folders, albums and artists are grouped in memory from the same list Tracks uses. For 1,000 tracks that takes milliseconds, and hidden folders and the minimum duration apply automatically. No new tables or queries are needed.
- **Detail routes are children of the Library branch** (`/library/folder`, `/library/album`, `/library/artist`). Their parameters go in query strings, because folder paths contain slashes and names can be Ethiopic. Back returns to the right tab; the breadcrumb replaces the folder page rather than stacking it.
- **Detail screens look a group up in the live track list.** If the group disappears (hidden, or its files deleted), the screen shows C07 rather than crashing.
- **The queue stays in `PlayQueue`.** Reorder, remove, undo and clear are unit-tested there. The sheet only calls the controller and redraws from the snapshot.
- **Timer and fade live in the handler.** The handler is the one place that survives the UI closing. The fade steps the volume in 250 ms intervals, and every exit path (end, cancel, pause, a new song) puts the volume back.
- **Tests:**
  - unit tests for the queue changes and for the folder, album and artist grouping
  - handler tests for the timer under `fake_async`
  - widget tests for each sheet, tab and detail screen in the empty and data states, at 1.3× text in light and dark
  - a 1,000-song queue test that checks the sheet opens at the current song
- **On the emulator:** reorder, remove and undo in the sheet; a 1-minute custom timer with the screen off (fade, then pause); browsing the test files' folders, albums and artists; hiding a folder and undoing it.

### Acceptance Criteria

Story 009
- [ ] Queue button on Now Playing opens C02 with the current song highlighted and upcoming songs below
- [ ] Dragging changes the play order
- [ ] Swiping removes a song with an undo snackbar; the current song can't be removed
- [ ] "Clear queue" removes everything after the current song
- [ ] Tapping a row plays it
- [ ] With shuffle on, C02 shows the shuffled order
- [ ] A 1,000-song queue opens quickly, scrolled to the current song

Story 010
- [ ] C05 offers 15 / 30 / 45 / 60 min, end of current song, custom (1–180 min)
- [ ] Remaining time shows in C05 and on S08; the timer can be cancelled
- [ ] At the end, the volume fades over 5 s, then playback pauses; the volume is normal for the next play
- [ ] "End of current song" stops when the song ends
- [ ] Works in the background and with the screen off (emulator)
- [ ] Pausing keeps the timer counting; an out-of-range custom value disables Save with a message
- [ ] Timer logic tested with a fake clock

Story 011
- [ ] Folders lists every folder with visible songs: name, song count, path
- [ ] S11a: breadcrumb, subfolders first (with the count of all songs below), then songs, Play all / Shuffle
- [ ] Tapping a breadcrumb segment opens that folder
- [ ] Hide removes the folder's songs everywhere, with an undo snackbar
- [ ] No folders → C07; Ethiopic folder names keep the Ethiopic line height

Story 012
- [ ] Album grid with cover, name and artist; sort by name, artist or year; 2 columns on phones
- [ ] S12a: cover, name, artist, year, track count, total duration, numbered list (track number, then title), Play / Shuffle
- [ ] Missing cover → themed placeholder
- [ ] Songs without an album group under "Unknown album"; mixed artists → album artist or "Various artists"

Story 013
- [ ] Artist list with avatar (album cover or initial) and song count
- [ ] S13a: their albums and songs, Play / Shuffle
- [ ] Songs without an artist group under "Unknown artist"

Quality
- [ ] `flutter analyze`, `dart format`, all tests clean; 1.3× text, light/dark, no overflow
- [ ] Checked on the Android emulator; still builds for iOS
