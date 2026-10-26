---
stage: implement
bolt: 008-local-library-and-player-ui
created: 2026-10-26T10:36:47Z
---

## Implementation Walkthrough: local-library-and-player-ui (bolt 5 of 5)

### Summary

- **Tracks multi-select:** a long-press starts it. A selection bar can add the songs to a playlist or the queue, favorite or unfavorite them, or hide them with Undo. Back ends it.
- **Play history:** the player counts a play after 30 s of actual listening. The Playlists tab gets three read-only auto playlists, each with its own page: Recently added, Most played and Recently played.
- **Settings:** a Library section (hidden folders and songs with Unhide, Rescan, minimum length) and a Playback section (sleep timer default, unplug, interruptions, gapless).
- **Gapless:** implemented, not deferred. It still needs a check by ear on the emulator.

### Structure Overview

- **Data.**
  - **Play history:** a new `HistoryDao` on the existing `play_events` table, so no schema change or migration.
  - **Library DAO:** gains the hidden lists, batch hide / unhide, and a one-shot count of visible tracks. The count shares its filter with the visible-tracks query.
  - **Collections DAO:** gains batch favorite / unfavorite.
  - **Settings:** five new keys in `SettingsRepository`, with defaults and validation of saved values.
- **Player.**
  - **Play counter:** a plain class, fed by the handler with loads, play/pause, position updates and track ends.
  - **Backend:** takes `PlaybackOptions` (unplug, interruptions). It can preload a next file and reports when that file takes over by itself.
  - **Handler:** keeps the preloaded file in step with the queue. `PlayQueue` gains `upcoming`, the item the queue would move to at the end of the current one.
- **Application.**
  - Auto playlists are joined with the visible tracks, like favorites and playlists. Hidden, missing and too-short songs drop out before the top 50 is taken.
  - Two shell-level providers: one stores counted plays (and prunes old ones at start), the other sends Settings → Playback to the player.
- **Presentation.**
  - **Tracks:** the selection bar replaces the search field and the Play / Shuffle bar while selecting.
  - **Settings:** two new groups, two new pages, and a shared choice sheet.
  - **C05:** preselects the default.

### Completed Work

- [x] `packages/zema_core/lib/src/player/play_queue.dart` - `upcoming`: what plays after the current item without moving the queue
- [x] `apps/mobile/lib/app/database/history_dao.dart` - record a play, prune before a date, track IDs by play count and by last play (dates compared with `julianday`)
- [x] `apps/mobile/lib/app/database/library_dao.dart` - batch hide / unhide; watch hidden folders and hidden songs; count visible tracks (shared filter)
- [x] `apps/mobile/lib/app/database/collections_dao.dart` - batch favorite (keeps existing times) and unfavorite
- [x] `apps/mobile/lib/app/database/zema_database.dart` - registers `HistoryDao` (generated code refreshed)
- [x] `apps/mobile/lib/features/settings/data/app_settings.dart` - minimum length, sleep timer default (`SleepTimerDefault`), unplug, interruptions, gapless
- [x] `apps/mobile/lib/features/settings/data/settings_repository.dart` - the story's keys; unknown or out-of-range saved values fall back to defaults
- [x] `apps/mobile/lib/features/settings/application/settings_controller.dart` - setters with the existing apply-then-save pattern
- [x] `apps/mobile/lib/features/player/data/play_counter.dart` - counts a play after 30 s of playing (or a short song's full length or end), once per play
- [x] `apps/mobile/lib/features/player/data/audio_backend.dart`:
  - `PlaybackOptions`
  - unplug pauses only when on
  - interruptions switch the audio session's "pause when ducked" and re-request focus while playing
  - next-file preload and "advanced" events
- [x] `apps/mobile/lib/features/player/data/zema_audio_handler.dart`:
  - feeds the counter; publishes counted plays
  - applies options
  - updates the preload after every queue, repeat, shuffle or sleep change
  - moves the queue on when the preloaded file takes over
- [x] `apps/mobile/lib/features/player/application/player_providers.dart` - options from Settings and the provider that applies them; queueing a list
- [x] `apps/mobile/lib/features/library/data/history_repository.dart` - play history for the app, with the one-year retention
- [x] `apps/mobile/lib/features/library/data/library_repository.dart`, `collections_repository.dart` - the new DAO operations
- [x] `apps/mobile/lib/features/library/application/play_history.dart` - recording and pruning; the three auto playlists
- [x] `apps/mobile/lib/features/library/application/track_selection.dart` - the selected songs, or none when not selecting
- [x] `apps/mobile/lib/features/library/application/library_providers.dart` - minimum length from Settings; hidden folders and songs
- [x] `apps/mobile/lib/features/library/application/favorites.dart` - favorite or unfavorite many at once
- [x] `apps/mobile/lib/features/library/presentation/tracks_view.dart` - long-press, tap to toggle, checkboxes, back ends selection, songs leaving the library leave the selection
- [x] `apps/mobile/lib/features/library/presentation/widgets/track_selection_bar.dart` - count, Select all, and the four actions with their snackbars (Undo for hide)
- [x] `apps/mobile/lib/features/library/presentation/widgets/track_row.dart` - long-press and a selected tint
- [x] `apps/mobile/lib/features/library/presentation/add_to_playlist_sheet.dart` - a sheet that adds several songs to one playlist (or a new one) and closes
- [x] `apps/mobile/lib/features/library/presentation/playlist_dialog.dart` - returns the saved playlist's name with its ID
- [x] `apps/mobile/lib/features/library/presentation/playlists_view.dart` - the Auto playlists heading and rows
- [x] `apps/mobile/lib/features/library/presentation/auto_playlist_screen.dart` - the read-only page: icon, name, count and duration, Play / Shuffle, rows with the song menu, C07 when empty
- [x] `apps/mobile/lib/features/settings/presentation/settings_screen.dart` - the Library and Playback groups; Rescan's spinner, result count, failure retry, and no-access path to the Library tab
- [x] `apps/mobile/lib/features/settings/presentation/hidden_folders_screen.dart`, `hidden_songs_screen.dart` - the hidden items with Unhide, C07 when none
- [x] `apps/mobile/lib/features/settings/presentation/widgets/choice_picker.dart` - a radio sheet like the language picker
- [x] `apps/mobile/lib/features/settings/presentation/widgets/settings_row.dart` - an optional trailing widget (switch, spinner)
- [x] `apps/mobile/lib/features/player/presentation/sleep_timer_sheet.dart` - the default option shown selected with a check
- [x] `apps/mobile/lib/app/app_shell.dart`, `routes.dart`, `router.dart` - the two shell providers; auto playlist and hidden-items routes
- [x] `apps/mobile/lib/l10n/app_en.arb` - 41 strings
- [x] `apps/mobile/test/helpers/fake_player.dart` - the fake backend records the preload and options, and can simulate a gapless takeover
- [x] `apps/mobile/test/features/settings/...`, `test/features/library/presentation/playlists_test.dart` - updated for the new sections and the auto playlists

### Key Decisions

- **No timer in the play counter.** It checks on the player's position updates, which `just_audio` sends several times a second while playing.
  - A first version used a 30 s timer. That left a pending timer in every widget test that ends with a song playing (50 tests).
  - Without one, nothing keeps running once playback stops.
- **What counts as a play:** time actually playing, measured with `clock`.
  - Pauses, loading and the jump of a seek don't add time.
  - A new queue entry or a repeat-one loop starts a new play.
  - Seeking back or Previous within 3 s of the start doesn't.
- **Interruptions use `audio_session`'s own switch.** With "pause when ducked", it turns duck requests into pause events, which `just_audio` pauses for and resumes after; without it, Android lowers the volume. Calls take full focus and always pause.
  - The setting is captured when focus is requested, so changing it while playing asks for focus again.
- **Gapless keeps one file in the backend's hands.**
  - The handler stays the only owner of the queue.
  - The backend holds at most the current file and the next one.
  - When the next one takes over, the finished one is dropped, and the handler moves the queue on and preloads the following file.
  - With gapless off, repeat one, or "stop at end of song", nothing is preloaded and the old load-per-track path runs.
  - If the queue changed before the preload caught up, the handler loads what the queue says.
- **Rescan reports a fresh count from the database** (a one-shot query with the same filter as the list). Reading the list provider straight after a scan could still show the old count.
- **Multi-select favorite** favorites all selected songs, or unfavorites them all when every one already is.
- **The selection bar reads providers up front.** Ending selection removes the bar before the action's awaits finish.
- **Settings choices open bottom sheets**, matching the language picker, rather than dialogs.

### Deviations from Plan

- **Play counter:** no timer (see above). Same behavior, simpler tests.
- **Choice sheets:** bottom sheets instead of dialogs, to match the existing pickers.
- **Hidden songs list:** leaves out missing files, which wouldn't show anywhere even if unhidden.

### Dependencies Added

- None.

### Developer Notes

- **Restore at start:** the counter starts a new play, so resuming the saved song and listening 30 s counts once.
- **Settings tests** now use a tall screen. The list builds lazily and About is below the fold on 800×600.
