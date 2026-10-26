---
stage: plan
bolt: 008-local-library-and-player-ui
created: 2026-10-26T10:17:06Z
---

## Implementation Plan: local-library-and-player-ui (bolt 5 of 5)

### Objective

Close intent 002:
- multi-select in Tracks (S10)
- play history, with the three read-only auto playlists on the Playlists tab (S15)
- the Library and Playback sections of Settings (S28)
- the intent's "Done when" checks, as far as the emulator allows

Stories: 018-track-multi-select, 019-play-history-and-auto-playlists, 020-library-settings, 021-playback-settings.

There are no mockups for these screens. They follow the design system and reuse the patterns already in Tracks, the playlist page and Settings.

### Deliverables

**1. Multi-select in Tracks (story 018)**
- `application/track_selection.dart`: a small Notifier holding the selected track IDs, or null when not selecting. It is scoped to the Tracks tab and cleared when the tab is left.
- `TrackRow` gets an optional `onLongPress`, and a checkbox in place of the More button while selecting.
- `tracks_view.dart`, while selecting:
  - The search field and the Play / Shuffle bar are replaced by a selection bar: Close, "N selected", Select all (the visible, filtered list), then Add to playlist, Add to queue, Favorite and Hide.
  - A row tap toggles it instead of playing.
  - Back (system or the Close button) ends selection without changes.
  - Songs that disappear from the list (hidden elsewhere, a rescan) drop out of the selection.
- The actions reuse the song-menu operations, extended to lists:
  - **Add to playlist:** a sheet with "New playlist" and the playlists. A tap adds every selected song (songs already there are skipped), then "Added N songs to X".
  - **Add to queue:** at the end, in list order. With nothing playing they become the queue, loaded paused, as for one song.
  - **Favorite:** favorites them all. If every selected song is already a favorite, the button reads "Remove from favorites" and unfavorites them.
  - **Hide:** hides them all in one transaction, then "N songs hidden" with Undo, which unhides them.
  - Each action ends selection and shows a snackbar.

**2. Play history and auto playlists (story 019)**
- `lib/features/player/data/play_counter.dart`, owned by the handler:
  - A play starts when a track is loaded. That covers a new queue entry and each repeat-one loop.
  - It counts time actually spent playing, using `clock` and a timer. Seeking, in either direction, doesn't count as listening.
  - Once that time reaches 30 s, or the whole track for songs under 30 s, it reports one play. Seeking back or pausing within the same play never reports it again.
  - Songs under 30 s also count when they play to the end.
- The handler gets a `playCounted` stream (like `unplayable`).
- `lib/app/database/history_dao.dart`, a new Drift DAO on the existing `play_events` table (schema version 1, so no migration):
  - record a play
  - prune events older than a year
  - watch track IDs by play count (ties broken by the latest play)
  - watch track IDs by their latest play, newest first
  - The story suggests putting this in the library DAO. A separate DAO keeps `LibraryDao` about tracks and hidden items, which is how `CollectionsDao` was split out in bolt 007.
- `application/play_history.dart`:
  - a provider kept alive by the app shell that stores each counted play and prunes old events once at start
  - `autoPlaylistProvider(kind)`, where kind is one of:
    - **Recently added:** visible tracks added in the last 30 days, newest first. This comes straight from `libraryTracksProvider`, no query.
    - **Most played:** the top 50 visible tracks.
    - **Recently played:** the last 50 distinct visible tracks, newest first.
  - The ID lists are joined with the visible tracks before the 50 are taken. So hidden, missing and too-short songs are left out and don't use up places.
- `playlists_view.dart`: after the user's playlists, an "Auto playlists" heading and three rows (icon, name, song count). They always show, even when empty.
- `presentation/auto_playlist_screen.dart`, route `/library/auto-playlist?kind=…`:
  - icon header, name, "N songs · duration", Play and Shuffle
  - rows with the song menu
  - no drag, swipe, rename, delete or Add songs
  - when empty, C07 says what fills it
- Events are keyed by Zema's track ID, which a rescan keeps, so history survives restarts and rescans. A test covers this.

**3. Library settings (story 020)**
- `AppSettings` and `SettingsRepository` gain `minTrackSeconds` (0 = off, 10, 30, 60; default 30). `minTrackDurationProvider` reads it, so the visible-tracks query re-runs with no rescan.
- `LibraryDao` gains `watchHiddenFolders` and `watchHiddenTracks` (hidden songs with their titles; missing files left out). A batch `hideTracks` / `unhideTracks` also serves multi-select.
- Settings gets a **Library** group between General and About:
  - **Hidden folders** (count) → `hidden_folders_screen.dart`: each folder path with an Unhide button; C07 when none.
  - **Hidden songs** (count) → `hidden_songs_screen.dart`: art, title, artist, Unhide; C07 when none.
  - **Rescan library:**
    - The row shows a spinner while the scan runs, then "Found N songs" (the library's song count after the scan).
    - A failure shows the scan-failed snackbar with Try again.
    - With no access, it opens the Library tab. The permission flow from story 003 already runs there: the explanation, Grant access, or Open settings.
  - **Ignore audio shorter than:** a dialog with Off / 10 s / 30 s / 60 s. It applies at once and is saved.
- Routes: `/settings/hidden-folders`, `/settings/hidden-songs`.

**4. Playback settings (story 021)**
- `AppSettings` and `SettingsRepository` gain the four keys from the story:
  - `sleepTimerDefault`: none, 15, 30, 45 or 60 minutes, or end of song; default none
  - `pauseOnUnplug`: default true
  - `duckOnInterruption`: default false, i.e. Pause
  - `gapless`: default true
- Settings gets a **Playback** group after Library:
  - Sleep timer default (a choice dialog)
  - Pause when headphones are unplugged (switch)
  - When another app plays sound (a Pause / Lower volume dialog)
  - Gapless playback (switch)
- **C05** shows the default option selected (highlighted, with a check) so it's one tap away. Nothing starts until the user taps an option.
- **Applying the options:** `PlaybackOptions` goes to the handler, and from there to the backend. A provider in the app shell sends the current value at start and on every change.
  - **Unplug:** `JustAudioBackend` already listens for "becoming noisy". It now pauses only when the option is on.
  - **Interruptions:**
    - The audio session is reconfigured with `androidWillPauseWhenDucked` = not ducking.
    - With Pause, `audio_session` turns duck requests (navigation prompts, notification sounds) into pause events. `just_audio` pauses and then resumes after them.
    - With Lower volume, Android lowers our volume instead.
    - Calls take full focus, so they always pause.
    - I checked this in the installed `audio_session` 0.2.4 and `just_audio` 0.10.6 sources, so no own interruption handling is needed.
  - **Gapless (Should):**
    - The backend preloads the next track in a two-item `just_audio` playlist. When the player moves on by itself, the backend reports "advanced" instead of "completed", and the handler moves the queue on without loading.
    - The handler updates the preloaded next track whenever it changes: queue edits, shuffle, repeat, the end of the queue, and "stop at end of song", which must not advance.
    - With gapless off, or for repeat one, there's no preload and today's load-per-track path is used.
    - The story allows deferring this if it complicates the queue. If it does, I'll keep the setting stored, record gapless as open, and say so at the implement checkpoint. I won't ship a fragile queue.

**5. Strings** in `app_en.arb`, about 45:
- the selection bar and its snackbars
- the auto playlist names and empty states
- the Library and Playback rows, their dialogs and values, the hidden lists' empty states and Unhide
- "Found N songs"

### Dependencies

- **No new packages.** `audio_session` and `just_audio` already cover interruption and unplug handling and two-item playlists. `clock` and `fake_async` are already used for the sleep timer.
- **From earlier bolts:**
  - `play_events`, `hidden_folders`, `hidden_tracks` tables
  - `libraryTracksProvider`, `filterTracks`
  - `PlaylistsController.add` (already takes a list), `FavoritesController.set`
  - the handler's `addToQueue(List)`
  - `LibrarySyncController.sync`, `libraryAccessProvider`
  - `SettingsGroup` / `SettingsRow`, the C04 sheet, `PlaylistCollage`, `PlayShuffleBar`, `EmptyState`

### Technical Approach

- **The same visible-tracks join as favorites and playlists.** History stores IDs only. Auto playlists combine them with `libraryTracksProvider`, so hidden folders and songs, missing files and the minimum duration apply the same way everywhere.
- **Play counting is a plain class with a clock and a timer**, kept apart from `just_audio`, so it can be unit-tested with `fakeAsync`. The handler only tells it about loads, play/pause and completion.
- **Settings stay in `SettingsController`** with the existing pattern: change the state at once, then save, logging a failed save. The player reads them through one provider, so the handler stays free of Riverpod.
- **Selection is local to Tracks.** It's a Notifier the view watches, with a `PopScope` so back ends it. The other tabs are out of scope.
- **Tests:**
  - play counter (fake clock):
    - counts once at 30 s of playing
    - pause time doesn't count
    - seeking doesn't double-count
    - a short song counts at its end
    - a repeat-one loop counts again; a skip before 30 s doesn't count
  - history DAO (in-memory database): record, top by count with ties, latest distinct first, prune, kept after a rescan
  - auto playlists: hidden, missing and too-short songs left out before the top 50; Recently added's 30-day edge
  - handler: plays reported to the stream; options reach the fake backend; gapless advance, end of queue, repeat one, end-of-song sleep and queue edits updating the preload
  - settings repository and controller: new keys, defaults, unknown values
  - widget tests:
    - multi-select: long-press, toggle, Select all after a search, each action and its snackbar, Undo for hide, back ends it
    - auto playlists: the section, the page without edit controls, the empty state
    - Settings: both groups in order; the hidden lists with Unhide bringing songs back to Tracks; Rescan's spinner, result and no-access path; min duration changing the list at once; each playback option saved; C05 preselecting the default
  - 1.3× text, light and dark, for each new screen
- **On the emulator:**
  - multi-select actions
  - play a song past 30 s, then see it in Recently played and Most played after a restart
  - set min duration to Off and see short files appear
  - unhide from Settings; Rescan
  - toggle unplug with a simulated headset (as far as the emulator allows)
  - listen across a track change with gapless on
- **Intent "Done when":**
  - Restart persistence and background playback are checked on the emulator.
  - The 1,000-track scan time, 60 fps scrolling and 30 minutes screen-off with battery saver need a real mid-range phone. If none is available they stay recorded as open, as the bolt notes allow.

### Acceptance Criteria

Story 018
- [ ] Long-pressing a row in Tracks starts selection with that row selected and a bar showing the count
- [ ] Taps toggle rows; Select all selects the visible (filtered) list
- [ ] Add to playlist, Add to queue, Favorite and Hide apply to every selected song, end selection and show a snackbar (Undo for Hide)
- [ ] Back ends selection without changes

Story 019
- [ ] A track playing 30 s (or to its end if shorter) stores one play event; seeking or replaying within that play doesn't double-count
- [ ] Playlists shows read-only Recently added (30 days), Most played (top 50) and Recently played (last 50, newest first)
- [ ] An auto playlist page has Play and Shuffle but no reorder, remove or rename
- [ ] Counts and history survive restart and rescan
- [ ] Events older than a year are pruned at start
- [ ] Hidden and missing tracks are left out of auto playlists
- [ ] Counting unit-tested with a fake clock; queries with an in-memory database

Story 020
- [ ] Settings shows a Library section between General and About
- [ ] Hidden folders / Hidden songs list hidden items with Unhide; unhidden items come back everywhere
- [ ] Rescan library shows progress, then the number of tracks found
- [ ] Ignore audio shorter than: Off / 10 / 30 / 60 s (default 30 s), applied without a rescan and saved
- [ ] Rescan with no access starts the permission flow

Story 021
- [ ] Settings shows a Playback section after Library
- [ ] The sleep timer default is preselected in C05
- [ ] Pause when headphones are unplugged (default on); off → unplugging doesn't pause
- [ ] When another app plays sound: Pause / Lower volume (default Pause); Lower volume ducks short interruptions, calls still pause
- [ ] Gapless playback (default on) plays consecutive tracks without a gap (Should; may be deferred, see Deliverables)
- [ ] All values kept after a restart

Quality
- [ ] `flutter analyze`, `dart format`, all tests clean; 1.3× text, light and dark, no overflow
- [ ] Checked on the Android emulator; still builds for iOS
- [ ] Intent "Done when" checks run or recorded as open
