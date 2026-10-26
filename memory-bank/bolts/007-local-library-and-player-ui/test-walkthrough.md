---
stage: test
bolt: 007-local-library-and-player-ui
created: 2026-10-26T09:46:03Z
---

## Test Report: local-library-and-player-ui (bolt 4 of 5)

### Summary

- **Tests**: 504/504 passed:
  - 442 in `apps/mobile`, up from 382
  - 62 in `packages/zema_core`, up from 56
- **Coverage**: 94.2% of lines in `apps/mobile/lib/` excluding generated code (3557/3777), up from 93.7%; 95.3% without Drift's table declarations. The new DAO, the favorites and playlist providers, the add-to-playlist sheet and the collage are at 100%.
- **CI sequence run locally**: format check, `flutter analyze`, `flutter test`, `dart analyze`, `dart test` all exit 0; generated localizations in sync. The iOS simulator build compiles.
- **Emulator**: checked once it was free; see Notes.

### Test Files

- [x] `packages/zema_core/test/library/playlist_order_test.dart`:
  - name key: letter case and spaces ignored; only spaces is empty
  - visible order: hidden songs keep their slots; unknown IDs ignored; a song still being removed stays put
- [x] `apps/mobile/test/app/database/collections_dao_test.dart` (in-memory database):
  - favorites: newest first, adding twice keeps the first time, remove and restore in place
  - playlists: trimmed name and empty description, unique names in any case (create and rename, its own name allowed), empty playlists listed
  - entries: add skips songs already there, remove and insert at the old index, reorder, cascade on delete
  - favorites and playlists kept through a rescan with a missing file
- [x] `apps/mobile/test/features/library/application/collections_test.dart`:
  - the playlist model: visible songs vs all stored, duration, collage choice (four albums → four covers, fewer → one, empty → none)
  - name check: empty, spaces only, taken in any case, own name when renaming
  - providers over a real database: favorites joined with visible tracks, newest first, hearts for hidden ones; undo restores the place; playlists by name; reorder keeps a hidden song's slot; toggle adds and removes
- [x] `apps/mobile/test/features/library/data/audio_share_service_test.dart` - the channel call carries the content URI and title; a failure returns false; unsupported elsewhere
- [x] `apps/mobile/test/features/player/data/zema_audio_handler_test.dart` - Play next after the current song; Add to queue at the end; with nothing queued, both load the song paused
- [x] `apps/mobile/test/features/library/presentation/favorites_test.dart`:
  - C07 when empty
  - newest first, Play order, search
  - swipe and Undo in place; the screen-reader remove action
  - a hidden favorite is not listed but comes back when unhidden
  - 1.3× light and dark
- [x] `apps/mobile/test/features/library/presentation/playlists_test.dart`:
  - tab: Create card only when empty; playlists by name with counts
  - dialog: Create disabled when empty, "Enter a name" for spaces, taken name message, Create opens the new playlist with its description; Cancel creates nothing
  - page: name, count and duration, Play order; drag saves the order; a hidden song keeps its slot; swipe and Undo in place; Rename (filled in, own name allowed, taken name rejected); Delete asks, Cancel keeps, Delete goes back; unknown playlist C07; empty playlist offers Add songs
  - picker: songs already in checked and disabled, button disabled with nothing picked, picks kept across searches, added in pick order and back to S17
  - 1.3× light and dark: tab, dialog, page, picker (with a long Ethiopic name)
- [x] `apps/mobile/test/features/library/presentation/song_menu_test.dart`:
  - every action listed; no lyrics or edit info
  - Play next and Add to queue with snackbars; Add to queue with nothing playing shows the mini player
  - favorite from the menu shows on the Favorites tab and Now Playing; unfavoriting on Now Playing updates the tab
  - Hide everywhere and Undo; hiding the playing song keeps it playing and queued
  - Share, and the failure snackbar
  - Go to album / artist; from Now Playing the player closes
  - C04: checkmarks, toggling, the sheet stays open; New playlist creates it with the song
  - 1.3× light and dark: menu and sheet
- [x] `apps/mobile/test/features/library/presentation/playlist_collage_test.dart` - 2×2 grid of half-size covers, a single cover, the empty icon
- [x] `apps/mobile/test/features/library/presentation/tracks_view_test.dart` - the six tabs
- [x] `apps/mobile/test/helpers/fake_library.dart`, `apps/mobile/test/helpers/pump_app.dart` - a fake share service; `pumpZemaApp` takes a database and a share service

### Acceptance Criteria Validation

Story 014: Favorites
- ✅ **Favorite from Now Playing or the menu updates the heart everywhere**: song menu tests
- ✅ **Newest first, with search, Play and Shuffle**: Favorites tests
- ✅ **Remove with Undo in the same place**: Favorites, DAO and provider tests
- ✅ **Kept through restart and rescan; missing hidden, not removed**: DAO rescan test; hidden favorite test
- ✅ **Empty → C07 explaining how to add one**: Favorites test

Story 015: Playlists
- ✅ **Create card, then playlists with collage, name and count**: tab and collage tests
- ✅ **Name required and unique, description optional, Save disabled, duplicate message**: dialog and DAO tests
- ✅ **S17: collage, name, count, duration, Play / Shuffle**: page test
- ✅ **Drag saves the order**: page test (and the stored order checked)
- ✅ **Swipe removes with Undo**: page test
- ✅ **Rename opens S16; Delete asks, then deletes**: page tests
- ✅ **Kept through restart and rescan**: DAO rescan test
- ✅ **No playlists → only the Create card**: tab test (auto playlists come with 019)
- ✅ **Adding a song already there does nothing**: DAO test

Story 016: Add songs picker
- ✅ **"Add songs" opens S18 with checkboxes and search**: picker tests
- ✅ **Songs already in are marked and can't be added**: picker test
- ✅ **Sticky "Add N songs" adds to the end and returns; disabled with nothing picked**: picker test
- ✅ **Checks kept across searches**: picker test

Story 017: Song menu and add to playlist
- ✅ **Menu from rows and Now Playing with every action**: song menu tests
- ✅ **Play next / Add to queue with a snackbar**: song menu and handler tests
- ✅ **C04 with checkmarks; a tap adds or removes at once**: C04 test
- ✅ **New playlist in C04 creates it with the song**: C04 test
- ✅ **Hide everywhere with Undo; a playing song keeps playing**: song menu tests
- ✅ **Share opens the share sheet with the file**: tests; emulator (the Android share sheet showed "Sharing 1 file · 02 Amlak.mp3")
- ✅ **Go to album / artist**: song menu tests
- ✅ **No lyrics or edit info**: song menu test

Quality
- ✅ **Analyze, format, all tests; 1.3× in light and dark without overflow**
- ✅ **Still builds for iOS**
- ✅ **Checked on the Android emulator**: see Notes

### Issues Found

- **An empty playlist page crashed.** The C07 state sits in a sliver that measured its child's height, which `EmptyState`'s layout builder can't report. The sliver now treats it as a scroll body.
- **Hide and Share were below the fold in the song menu.** Bottom sheets are capped at 9/16 of the screen by default, so on most phones the last menu items needed a scroll. The menu now takes the height it needs and still scrolls on short screens.
- **Test-side issues:**
  - Awaiting a database stream directly in a widget test hangs under the fake clock; such reads now go through `tester.runAsync`.
  - A failing widget test in this suite takes over 30 s to tear down, which first looked like more hangs.
  - Finders needed scoping: the Tracks search box behind a sheet is also a `TextField`, and the picker's empty button repeats the screen title.
  - A snackbar left from an earlier step covered Now Playing's buttons; the test lets it time out first.

### Notes

- **Mutation checks:** each of these makes a test fail:
  - an undone favorite getting a new time
  - adding a song that's already in a playlist
  - playlist undo putting the song at the end
  - the picker dropping picks when the search changes
  - reorder ignoring hidden songs' slots
  - favorites not newest first
  - queueing into an empty player starting playback
  - the song menu capped at 9/16 of the screen
- **Emulator:** once it was free, these were checked on the light theme:
  - **Song menu:** all eight items fit without scrolling (the 9/16 fix).
  - **Add-to-playlist sheet:**
    - "test" against the existing "Test" was rejected with the message
    - "Timket" was created with the song in it
    - ticking and unticking a playlist changed it at once, and the sheet stayed open
  - **Playlist page:** "N songs · duration" and the 2×2 collage show.
  - **Picker:**
    - the song already in the playlist was dimmed and marked
    - a pick survived a search
    - "Add 2 songs" added both in pick order and went back
  - **Reorder:** dragging a song to the top kept the new order after a force-stop and relaunch.
  - **Swipe and Undo:** a swiped playlist song came back in its place. My first attempt tapped Undo after the 4 s snackbar had gone, so that song stayed removed.
  - **Favorites:**
    - Now Playing has the More button, heart, add to playlist and queue
    - unfavoriting there showed C07 on Favorites; favoriting again listed it
    - swiping it away showed "Removed … from favorites" with Undo, and Undo restored it
  - **Hide:** the count dropped from 1007 to 1006 with "… is hidden", and Undo restored it.
  - **Share:** the Android share sheet opened with "Sharing 1 file · 02 Amlak.mp3", so the system could read the MediaStore URI we granted. Actually sending to an app (Drive, Gmail, Messages) needs an account on the emulator, so it's still open for a real phone.
- **Real phone, still open from bolts 004 and 005:** scrolling 1,000 tracks, 30 minutes screen-off with battery saver, the 1,000-file scan time.
