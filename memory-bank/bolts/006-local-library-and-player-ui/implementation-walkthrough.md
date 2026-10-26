---
stage: implement
bolt: 006-local-library-and-player-ui
created: 2026-10-26T07:53:18Z
---

## Implementation Walkthrough: local-library-and-player-ui (bolt 3 of 5)

### Summary

Now Playing has a second row with the sleep timer and the queue. The queue sheet reorders, removes with undo, clears and plays any entry. The sleep timer runs inside the player, so it also stops playback with the screen off. The Library tab gains Folders (with a breadcrumb and hide), Albums (a grid and an album page) and Artists (a list and an artist page). All three are grouped in memory from the same visible-tracks list as Tracks.

### Structure Overview

- **Player.** The queue logic stays in `PlayQueue` (`zema_core`). The handler gains queue-editing commands and the sleep timer, and publishes both through the snapshot. The two sheets only call `PlayerController` and redraw from the snapshot.
- **Library.**
  - Pure grouping functions turn the visible tracks into a folder index, albums and artists. Providers combine them with the live track stream.
  - Three views fill the new tabs. Three detail screens open as child routes of the Library branch, so the navigation bar and mini player stay.
  - Each detail screen looks its group up in the live list. If the group disappears, it shows C07.

### Completed Work

**Queue (story 009)**
- [x] `packages/zema_core/lib/src/player/play_queue.dart` - stable entry keys; removal returns what is needed to put the entry back in the same place, and restore does so (ignored once the queue has been replaced)
- [x] `apps/mobile/lib/features/player/data/player_snapshot.dart` - entry keys and the sleep timer added to the snapshot
- [x] `apps/mobile/lib/features/player/data/zema_audio_handler.dart` - move, remove, restore and clear-upcoming commands; sleep timer, fade and end-of-song stop
- [x] `apps/mobile/lib/features/player/application/player_providers.dart` - controller commands for the queue, shuffle-play and the timer; `sleepTimerProvider`
- [x] `apps/mobile/lib/features/player/presentation/queue_sheet.dart` - C02:
  - the whole queue in play order, earlier songs dimmed, opening at the current song
  - drag handles, swipe to remove with Undo, tap to play, Clear queue
  - a screen-reader action for remove

**Sleep timer (story 010)**
- [x] `apps/mobile/lib/features/player/data/sleep_timer.dart` - the two timer kinds: at a time, or at the end of the song
- [x] `apps/mobile/lib/features/player/presentation/sleep_timer_sheet.dart` - C05:
  - presets, end of song, and a custom dialog for 1–180 min (Save disabled with a message when out of range)
  - the time left and Cancel while a timer runs
  - a once-a-second countdown widget that rounds up to the second (changed in the test stage)
- [x] `apps/mobile/lib/features/player/presentation/now_playing_screen.dart` - secondary row: sleep timer (shows the time left, or "End of song") and queue

**Folders (story 011)**
- [x] `apps/mobile/lib/features/library/application/folder_tree.dart` - storage root and name (Phone, SD card), breadcrumb paths, folders that hold songs, folder contents with counts of everything below, all songs under a folder
- [x] `apps/mobile/lib/features/library/presentation/folders_view.dart` - S11
- [x] `apps/mobile/lib/features/library/presentation/folder_screen.dart` - S11a: breadcrumb (parent segments open that folder), subfolders, songs, Play all and Shuffle over everything below
- [x] `apps/mobile/lib/features/library/presentation/widgets/folder_row.dart` - folder row with a Hide menu; hide with an Undo snackbar; folder display names and paths
- [x] `apps/mobile/lib/features/library/data/library_repository.dart` - hide and unhide a folder

**Albums (story 012)**
- [x] `apps/mobile/lib/features/library/application/album_grouping.dart` - album identity, grouping, artist (album artist, a single shared artist, or various), most common year, track order, total duration, sort
- [x] `apps/mobile/lib/features/library/presentation/albums_view.dart` - S12: grid sized from the screen width and the measured text height; sort menu
- [x] `apps/mobile/lib/features/library/presentation/album_screen.dart` - S12a; also formats total durations ("48 min", "1 h 12 min")
- [x] `apps/mobile/lib/features/library/presentation/widgets/album_tile.dart` - cover with name and artist, read as one item by screen readers

**Artists (story 013)**
- [x] `apps/mobile/lib/features/library/application/artist_grouping.dart` - artists by tag as written, their songs, their albums (newest first) and avatar song
- [x] `apps/mobile/lib/features/library/presentation/artists_view.dart` - S13
- [x] `apps/mobile/lib/features/library/presentation/artist_screen.dart` - S13a: avatar, Play and Shuffle, a row of album covers, songs

**Shared and wiring**
- [x] `apps/mobile/lib/features/library/application/library_groups.dart` - folder, album and artist providers; remembered album sort
- [x] `apps/mobile/lib/features/library/presentation/widgets/play_shuffle_bar.dart` - label, extra actions, Shuffle and Play; now also used by Tracks
- [x] `apps/mobile/lib/features/library/presentation/widgets/track_row.dart` - optional track number in place of the art, optional trailing widget
- [x] `apps/mobile/lib/features/library/presentation/widgets/track_art.dart` - optional placeholder letter source (album or artist name)
- [x] `apps/mobile/lib/features/library/presentation/library_screen.dart` - Folders, Albums and Artists tabs live; Favorites and Playlists still "Coming soon"
- [x] `apps/mobile/lib/features/library/presentation/tracks_view.dart` - header uses the shared bar; sort menu kept as its own widget
- [x] `apps/mobile/lib/app/routes.dart`, `apps/mobile/lib/app/router.dart` - folder, album and artist routes under Library, with their parameters in the query string
- [x] `apps/mobile/lib/app/theme/zema_theme.dart` - snackbar and text-button colors (see Deviations)
- [x] `apps/mobile/lib/l10n/app_en.arb` - 45 strings with descriptions
- [x] `apps/mobile/test/features/library/presentation/tracks_view_test.dart` - the "Coming soon" check moved to Favorites

### Key Decisions

- **The undo snackbar has its own messenger in the queue sheet.** The page's messenger sits behind the modal sheet, so a snackbar sent there can't be seen.
- **Only Undo snackbars time out.** In this Flutter version, snackbars with an action stay until tapped by default. Undo snackbars set `persist: false` and disappear after the usual few seconds. "Scan failed, Try again" keeps the default and stays.
- **The queue sheet updates itself straight away after a drag or swipe.** A swiped row must leave the tree at once, and a dropped row shouldn't flash back. The sheet shows the edited order until the player publishes the change.
- **The fade steps the volume down every 250 ms.** Every way out (the fade finishing, cancel, pause, stop) puts the volume back to full.
- **The breadcrumb replaces the folder stack.** Tapping a segment goes to Library → that folder, so Back always returns to the Folders tab.
- **Album tile height is measured, not computed.** The text height comes from laying out Latin and Ethiopic sample text at the current text size. Computing it from the font size came out 0.5 px short on the emulator.

### Deviations from Plan

- **Snackbar colors (theme, from intent 001).**
  - The color scheme never set Material's inverse slots, so snackbar actions were drawn dark on a dark snackbar. The Undo button was invisible on the emulator.
  - Snackbars now use the same palette in the opposite brightness: its background, text and `accentText` for the action. These pairs are already contrast-checked in the design system.
- **Text-button color (theme).** Text buttons used bright gold, which fails contrast as text on light backgrounds, so they now use `accentText`. In dark mode `accentText` is gold, so dark mode looks the same.
- **Album numbers.** The album list numbers songs by position (1, 2, 3, …) in track-number order, rather than printing the tag's track number. Gaps and missing tags still give a clean list.

### Dependencies Added

- [x] `clock` - the handler reads the time through it, so tests can control it
- [x] `fake_async` (dev) - drives the timer and fade in tests

Both were already in the lockfile (through `flutter_test`), so no versions changed.

### Developer Notes

- **Checked on the emulator:**
  - Folders, a nested folder, the breadcrumb, hiding a folder, back to the tab
  - Albums: the grid, the year sort, "Various artists", the album page
  - Now Playing's new row; the queue sheet's drag and swipe, with the queue moving on correctly
  - Custom timer validation
  - A 1-minute timer with the screen off: playback paused at 40.7 s of a 48 s song, so the timer stopped it, not the song ending
- **Not yet checked on the emulator:** the queue Undo snackbar and text-button color after the fixes, the short-breadcrumb alignment, and the Artists screens. Someone was using the emulator window at the time, so I stopped sending taps. These are covered in stage 3.
- **Hidden folders while testing:** the emulator has no `sqlite3`. To unhide a folder, copy `app_flutter/zema.sqlite` out with `run-as`, edit it with the Mac's `sqlite3`, and copy it back while the app is stopped. Unhiding in Settings comes in story 020.
