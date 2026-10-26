---
stage: implement
bolt: 007-local-library-and-player-ui
created: 2026-10-26T08:43:57Z
---

## Implementation Walkthrough: local-library-and-player-ui (bolt 4 of 5)

### Summary

The Library's last two tabs are live:
- **Favorites:** with search, Play / Shuffle, and swipe to remove with Undo
- **Playlists:** create / rename with name checks, a playlist page with drag, swipe, Undo, rename and delete, and an add-songs picker

Every song row and Now Playing has a song menu: Play next, Add to queue, Add to playlist (a sheet with checkmarks), Favorite, Go to album / artist, Hide with Undo, and Share. Now Playing also gets a heart and an add-to-playlist button.

### Structure Overview

- **Data.** The favorites and playlist tables already existed (schema version 1), so there's no migration.
  - A new Drift DAO reads and writes them; every multi-row change runs in one transaction.
  - A repository wraps it, turning store errors into `DatabaseFailure` and a taken name into `DuplicateNameFailure`.
- **Application.**
  - Favorites and playlists are joined in memory with the visible-tracks stream, the same list every tab uses. Hidden songs, hidden folders, missing files and the minimum duration apply automatically, while the stored rows are kept.
  - Controllers return undo functions for removals.
- **Presentation.** One `showSongMenu` serves every list. The views keep a short-lived local order after a swipe or drag (like the queue sheet) until the database stream catches up.
- **Player.** Two new commands put a song next or at the end of the queue.
- **Share.** A new method on the existing Kotlin library channel opens the share sheet with the song's MediaStore URI.

### Completed Work

**Core (`packages/zema_core`)**
- [x] `lib/src/failures.dart` - `DuplicateNameFailure` for a playlist name that's already taken
- [x] `lib/src/library/playlist_order.dart`:
  - the name key that makes names unique (trimmed, lowercase)
  - fitting a new visible order into the stored order, so hidden songs keep their slots

**Data**
- [x] `apps/mobile/lib/app/database/collections_dao.dart`:
  - favorites: watch newest first, add, remove (returns the row), restore with the original time
  - playlists: watch with entries, create, rename, delete (entries cascade), with the duplicate-name check
  - entries: add to the end skipping songs already there, remove (returns the old index), insert at an index, save an order; positions are rewritten as 0, 1, 2, …
- [x] `apps/mobile/lib/app/database/zema_database.dart` - registers the new DAO (generated code regenerated)
- [x] `apps/mobile/lib/features/library/data/collections_repository.dart` - wraps the DAO with typed failures; removals return an undo function
- [x] `apps/mobile/lib/features/library/data/library_repository.dart` - hide and unhide one song
- [x] `apps/mobile/lib/features/library/data/audio_share_service.dart` - share a song's file on Android; unsupported elsewhere
- [x] `apps/mobile/android/app/src/main/kotlin/com/zemaapp/zema/LibraryChannel.kt` - `share`: a chooser with the content URI and read access granted to the receiving app; failures are reported back

**Application**
- [x] `apps/mobile/lib/shared/combine_async.dart` - joins two async values (first error, else loading until both have data)
- [x] `apps/mobile/lib/features/library/application/library_providers.dart` - repository and share service providers
- [x] `apps/mobile/lib/features/library/application/favorites.dart` - favorite IDs, the per-song heart, the visible favorites newest first, and the controller
- [x] `apps/mobile/lib/features/library/application/playlists.dart`:
  - the playlist model: visible songs, all stored IDs, total duration, collage covers
  - playlists by name; one playlist by ID
  - the name check: empty, or already taken
  - the controller: create, rename, delete, add, remove, reorder, toggle
- [x] `apps/mobile/lib/features/player/data/zema_audio_handler.dart`, `apps/mobile/lib/features/player/application/player_providers.dart` - Play next and Add to queue; with nothing queued, the song is loaded paused

**Presentation**
- [x] `apps/mobile/lib/features/library/presentation/song_menu.dart` - C03 and the More button used by every row
- [x] `apps/mobile/lib/features/library/presentation/add_to_playlist_sheet.dart` - C04: New playlist, then each playlist with a checkbox that adds or removes the song at once
- [x] `apps/mobile/lib/features/library/presentation/playlist_dialog.dart` - S16:
  - name and optional description
  - Save disabled while the name is empty or taken
  - "Enter a name" once edited; a message for a taken name, also when the save itself finds it taken
- [x] `apps/mobile/lib/features/library/presentation/favorites_view.dart` - S14
- [x] `apps/mobile/lib/features/library/presentation/playlists_view.dart` - S15: Create card (opens the new playlist after saving), then playlists with collage and count
- [x] `apps/mobile/lib/features/library/presentation/playlist_screen.dart` - S17:
  - header with Add songs; drag, swipe and Undo
  - menu with Rename and Delete (confirmation)
  - empty and not-found states
- [x] `apps/mobile/lib/features/library/presentation/add_songs_screen.dart` - S18:
  - search; songs already in the playlist checked, dimmed and disabled
  - picks kept across searches; sticky "Add N songs" button
- [x] `apps/mobile/lib/features/library/presentation/widgets/playlist_collage.dart` - four covers, one cover, or a playlist icon
- [x] `apps/mobile/lib/features/library/presentation/widgets/library_search_field.dart` - the Tracks search box, now shared with Favorites and the picker
- [x] `apps/mobile/lib/features/library/presentation/widgets/swipe_remove_background.dart` - the swipe background, now shared with the queue sheet
- [x] `apps/mobile/lib/features/library/presentation/widgets/track_row.dart` - a null tap disables the row (picker)
- [x] `apps/mobile/lib/features/library/presentation/{tracks_view,folder_screen,album_screen,artist_screen}.dart` - More button on each row
- [x] `apps/mobile/lib/features/library/presentation/library_screen.dart` - all six tabs live
- [x] `apps/mobile/lib/features/player/presentation/now_playing_screen.dart` - More button in the top bar; heart and add to playlist in the secondary row; the sleep label can shorten (see Deviations)
- [x] `apps/mobile/lib/features/player/presentation/queue_sheet.dart` - uses the shared swipe background
- [x] `apps/mobile/lib/app/routes.dart`, `apps/mobile/lib/app/router.dart`:
  - S17 at `/library/playlist?id=…`, inside the Library branch
  - S18 at `/playlist-add?id=…`, above the shell
- [x] `apps/mobile/lib/l10n/app_en.arb` - 41 strings with descriptions; the unused "coming soon" tab message removed
- [x] `apps/mobile/test/features/library/presentation/tracks_view_test.dart` - checks the six tabs instead of a "Coming soon" tab

### Key Decisions

- **Join in memory rather than in SQL.** Favorites and playlists use the same visible-tracks list as every other tab. "Hidden everywhere" and "missing files hidden, not removed" then hold without repeating the visibility rules in more queries.
- **Reorder sends the visible order, not indexes.** Right after a swipe, the rows on screen and the stored playlist differ for a moment. Passing the new order of track IDs avoids mixing up indexes, and the core function puts hidden songs back in their slots.
- **Undo restores exactly.** A favorite comes back with its original time, so it returns to the same place in the newest-first list. A playlist song comes back at its old index in the stored order.
- **The song menu reads everything before it closes.** Its actions run after the sheet is gone. Providers are read up front, and snackbars and navigation use the page that opened the menu.
- **Share uses the MediaStore URI directly** through the existing Kotlin channel: no copy and no new package (agreed in the plan). On iOS the item is hidden.
- **Song menu feedback.** Play next, Add to queue and favoriting show a short snackbar, since the menu closes. Hiding a song shows Undo.
- **Playlists sort by name**, so the list doesn't jump while songs are toggled in C04.

### Deviations from Plan

- **Now Playing's sleep timer label shortens.** With the heart and add-to-playlist added, the secondary row overflowed by 23 px on a small phone at 1.3× text while a timer ran; the existing sleep-timer test caught it. The sleep button now takes the remaining width and its label ends in an ellipsis when it doesn't fit.
- **Fewer new strings than estimated** (41, not about 45). Removing from favorites, the "New playlist" title, and plain Create / Delete buttons reuse one string each.

### Dependencies Added

- None. No new packages; the Drift schema is unchanged.

### Developer Notes

- **Emulator:** the new build is installed, but I didn't run the planned checks. Right after launch, the app moved from the Favorites tab to Artists without any input from me, so someone was using it again; I sent no taps. The stage 3 checks on the emulator, once it's free:
  - favorite from Now Playing, then Favorites and Undo
  - create a playlist from C04
  - the picker; reorder, then restart and check the order is kept
  - share to another app; this also confirms the receiving app can read the MediaStore URI
  - hide a song and undo
- **All checks pass:**
  - `flutter analyze`, `dart format` and the 382 existing app tests (after the tab test change and the Now Playing fix)
  - `zema_core`: analyze and 56 tests
  - the iOS simulator build
  - New tests come in stage 3.
