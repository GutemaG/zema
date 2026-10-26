---
stage: plan
bolt: 007-local-library-and-player-ui
created: 2026-10-26T08:28:15Z
---

## Implementation Plan: local-library-and-player-ui (bolt 4 of 5)

### Objective

Let listeners organize their songs:
- Favorites (S14), with a heart on Now Playing and in the song menu
- user playlists: the Playlists tab (S15), the create / rename dialog (S16) and the playlist page (S17)
- the add-songs picker (S18)
- the song menu (C03) on every track row and on Now Playing, with the add-to-playlist sheet (C04)

Stories: 014-favorites, 015-playlists, 016-add-songs-picker, 017-song-menu-and-add-to-playlist.

There are no mockups for these screens. They follow the design system and reuse the patterns from Tracks, the album page and the queue sheet.

### Deliverables

**1. Data (stories 014, 015)**
- The `favorites`, `playlists` and `playlist_entries` tables already exist (schema version 1, story 002), so there is no schema change and no migration.
- `lib/app/database/collections_dao.dart`, a new Drift DAO:
  - favorites: watch (track ID and added time), add, remove, restore with the original added time (for undo)
  - playlists: watch all with their entries, create, rename (name and description), delete
  - entries: add songs to the end (songs already there are skipped), remove one, put one back at an index, save a new order
  - every multi-row change runs in one transaction, and positions are rewritten as 0, 1, 2, …
  - a duplicate name (the unique `name_key`) is reported as a `DuplicateNameFailure`
- `lib/features/library/data/collections_repository.dart`, which wraps the DAO for the UI.

**2. Favorites (story 014)**
- `application/favorites.dart`:
  - `favoriteIdsProvider` (a set, for hearts)
  - `isFavoriteProvider(trackId)`
  - `favoritesProvider`: the visible favorite tracks, newest first
  - `FavoritesController.toggle` and `remove`; `remove` returns an undo action
- `presentation/favorites_view.dart` (S14):
  - search field (the Tracks filter), Play and Shuffle
  - swipe a row away to remove it, with Undo, which puts it back in the same place
  - Empty → C07 explaining how to add a favorite (the heart on Now Playing or the song menu)
- Now Playing: a heart button in the secondary row, filled in the accent color when on.

**3. Playlists (story 015)**
- `application/playlists.dart`:
  - a `Playlist` model: ID, name, description, the visible tracks in order, the collage covers, the total duration
  - `playlistsProvider` (sorted by name)
  - `playlistProvider(id)`
  - `PlaylistsController`: create, rename, delete, add, remove (returns undo), move, toggle (for C04)
  - name validation (required, trimmed, unique ignoring case)
- `presentation/playlists_view.dart` (S15):
  - a "Create playlist" card first
  - then one row per playlist: collage, name, song count
  - The auto playlists section comes with story 019 in bolt 008.
- `presentation/widgets/playlist_collage.dart`:
  - four covers in a 2×2 grid when the playlist has four or more albums
  - otherwise the first song's cover
  - a playlist icon when empty
- `presentation/playlist_dialog.dart` (S16), a dialog for create and rename:
  - name and an optional description
  - Save is disabled while the name is empty or only spaces; a duplicate name shows a message and disables Save too
  - returns the saved playlist, so C04 can add the song to it
- `presentation/playlist_screen.dart` (S17), route `/library/playlist?id=…` inside the Library branch:
  - collage, name, description, "N songs · total duration", Play and Shuffle, Add songs
  - drag handles to reorder (saved at once); swipe a row away to remove it, with Undo
  - a menu with Rename (S16) and Delete (a confirmation dialog, then back to Playlists)
  - an empty playlist shows C07 with an "Add songs" button
  - a deleted or unknown playlist shows C07
- Hidden and missing songs stay in the database but don't show. A reorder only moves the visible songs; hidden ones keep their slots, so they return in place if unhidden.

**4. Add songs picker (story 016)**
- `presentation/add_songs_screen.dart` (S18), route `/playlist-add?id=…` above the shell, so the mini player doesn't cover the button:
  - every visible track with a checkbox, filtered by the Tracks search
  - songs already in the playlist are checked, dimmed and disabled, with "In playlist" for screen readers
  - selections are kept by track ID, so they survive a search change
  - a sticky "Add N songs" button at the bottom, disabled when nothing is selected; it adds the songs to the end and returns to S17

**5. Song menu and add-to-playlist (story 017)**
- `lib/features/library/presentation/song_menu.dart`, one `showSongMenu(context, track)` bottom sheet (C03):
  - header: art, title, artist
  - Play next, Add to queue
  - Add to playlist
  - Add to favorites / Remove from favorites
  - Go to album, Go to artist
  - Hide song
  - Share
  - View lyrics and edit info are not shown in this intent.
- Every track row gets a trailing "More" button that opens the menu:
  - Tracks, folder page, album, artist, Favorites, playlist page
  - Long-press stays free for multi-select (story 018).
- Now Playing gets a "More" button in the top bar.
- Play next and Add to queue:
  - new `insertNext` / `addToQueue` commands on the handler and controller, using the existing `PlayQueue.insertNext` and `add`
  - a snackbar confirms each
  - with nothing playing, the song becomes a one-song queue, loaded paused, so the mini player appears
- `presentation/add_to_playlist_sheet.dart` (C04):
  - "New playlist" opens S16; on save, the playlist is created and the song added
  - then the playlists, each with a checkmark if it holds the song
  - tapping one adds or removes the song at once; the sheet stays open
- Hide song: the song disappears from every list (the visible-tracks query already excludes hidden songs), with an Undo snackbar. If it is playing, it keeps playing and stays in the current queue.
- Share: opens the Android share sheet with the song's MediaStore content URI (see Dependencies).
- Go to album / Go to artist open S12a / S13a. From Now Playing, the player closes first.

**6. Wiring**
- Library tabs: Favorites and Playlists replace "Coming soon". All six tabs are now live.
- Routes: `AppRoutes.playlist(id)` and `AppRoutes.addSongs(id)`.
- Now Playing secondary row: sleep timer, then favorite, add to playlist (C04) and queue.

**7. Strings** in `app_en.arb`, about 45:
- the menu items and their snackbars
- favorites: empty state, removed + Undo
- playlists: Create, the dialog fields, its errors and buttons, the song count line, Delete confirmation, removed + Undo
- the picker: title, "Add N songs", "In playlist"
- the More button label

### Dependencies

- **Share — no new package.** The story's note suggests `share_plus`. `share_plus` needs a file path: it copies the file into its own cache, then shares that copy. Zema already has a library channel in Kotlin (`LibraryChannel.kt`). I'll add a `share` method to it that sends an `ACTION_SEND` intent with the MediaStore content URI and read permission granted to the receiving app. That means:
  - no copy of the audio file
  - no extra plugin or permissions
  - On iOS the Share item is hidden. iOS has no local library yet.
- **From earlier bolts:**
  - `libraryTracksProvider` (visible tracks); `filterTracks`
  - `LibraryDao.hideTrack` / `unhideTrack`
  - `PlayQueue.insertNext` / `add`; `PlayerController`
  - `TrackRow`, `TrackArt`, `PlayShuffleBar`, `EmptyState`
  - the queue sheet's swipe / drag / undo pattern
  - the album and artist routes

### Technical Approach

- **Favorites and playlists are joined to the visible tracks in memory.** The DAO streams the stored rows: favorite IDs with times, and playlists with their entries. Providers combine them with `libraryTracksProvider`, the same list every tab uses. Missing files, hidden songs, hidden folders and the minimum duration then apply everywhere, while the rows themselves are kept (FR-2). This is the same approach as Folders, Albums and Artists.
- **Undo puts things back exactly.**
  - A removed favorite is restored with its original added time, so it returns to the same place in the newest-first list.
  - A removed playlist song is put back at its old index in the full stored order.
- **Reorder saves the whole order in one transaction.** S17 shows the new order straight away, like the queue sheet, until the stream catches up.
- **The song menu is one function used everywhere.** The callers only pass the track. The menu reads favorites and playlists from providers, so the heart and checkmarks are always current.
- **Navigation from the menu** uses the sheet's context to close it first. Go to album/artist uses `context.go`, which also closes Now Playing.
- **Tests:**
  - DAO tests on an in-memory database:
    - favorites: add, remove, restore with the original time
    - playlists: duplicate names in any letter case
    - entries: add skips songs already there, remove and restore at an index, reorder, cascade on playlist delete
    - everything is kept after a rescan
  - unit tests:
    - joining with visible tracks (hidden and missing songs left out)
    - reorder with hidden songs keeping their slots
    - name validation; the collage cover choice
  - widget tests:
    - Favorites: list, search, swipe and Undo in place, empty C07
    - Playlists tab and the dialog: required, spaces only, duplicate, rename
    - playlist page: drag, swipe and Undo, rename, delete with confirmation, unknown playlist C07
    - picker: songs already in the playlist, selection kept across searches, button count and disabled state
    - song menu: every action, including the heart updating Now Playing and the rows
    - C04: toggle, and a new playlist with the song in it
  - 1.3× text, light and dark, for each new screen
- **On the emulator** (if it's free): favorite from Now Playing, then the Favorites tab and Undo; create a playlist from C04; add songs with the picker; reorder, then restart the app to see the order kept; share to another app; hide a song and undo.

### Acceptance Criteria

Story 014
- [ ] Favoriting from Now Playing or the song menu updates the heart everywhere at once
- [ ] Favorites lists favorited songs newest first, with search, Play and Shuffle
- [ ] Removing a song from Favorites shows Undo, which restores it in the same place
- [ ] Favorites survive a restart and a rescan; missing files are hidden, not removed
- [ ] No favorites → C07 explaining how to add one

Story 015
- [ ] S15: "Create playlist" card, then playlists with collage, name and count
- [ ] S16: name required and unique (trimmed, any letter case), description optional; Save disabled while invalid; duplicate shows a message
- [ ] S17: collage, name, count, total duration, Play and Shuffle
- [ ] Dragging a song saves the order
- [ ] Swiping a song removes it with Undo
- [ ] Menu: Rename opens S16; Delete asks for confirmation, then deletes
- [ ] Playlists and their order survive a restart and a rescan
- [ ] No playlists → only the Create card (auto playlists come with 019)
- [ ] Adding a song that's already in a playlist does nothing

Story 016
- [ ] "Add songs" on S17 opens S18: every visible track with checkboxes and a search field
- [ ] Songs already in the playlist are marked and can't be added again
- [ ] A sticky "Add N songs" button adds them to the end and returns to S17; disabled when nothing is selected
- [ ] Checked songs stay checked when the search changes

Story 017
- [ ] C03 from any track row or Now Playing: Play next, Add to queue, Add to playlist, Favorite / Unfavorite, Go to album, Go to artist, Hide, Share
- [ ] Play next / Add to queue put the song after the current one / at the end, with a snackbar
- [ ] C04: "New playlist" and existing playlists with checkmarks; a tap adds or removes the song at once
- [ ] "New playlist" in C04: saving S16 creates the playlist with the song in it
- [ ] Hide removes the song everywhere with Undo; a playing song keeps playing and isn't queued again
- [ ] Share opens the Android share sheet with the audio file
- [ ] Go to album / Go to artist open S12a / S13a
- [ ] View lyrics and edit info are not shown

Quality
- [ ] `flutter analyze`, `dart format`, all tests clean; 1.3× text, light and dark, no overflow
- [ ] Checked on the Android emulator; still builds for iOS
