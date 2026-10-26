---
intent: 002-local-library-and-player
phase: inception
status: complete
created: 2026-10-23T22:16:40Z
updated: 2026-10-24T19:18:00Z
---

# Requirements: Local Library and Player

> Source: `docs/roadmap.md` Stage 2 · screens/components: `docs/screens.md` S08, S10–S18,
> S28, C01–C05, C07, C08 · Complexity ★★☆☆☆ · No backend. Native code only if the
> scanner spike (FR-2) needs the Kotlin fallback.

## Intent Overview

A complete offline music player for the phone's audio files: library browsing (tracks,
folders, albums, artists, favorites, playlists) and background playback with system
controls. Android only; on iOS the app keeps building and the Library tab shows a
"not available on iOS yet" state.

## Business Goals

| Goal | Success Metric | Priority |
|------|----------------|----------|
| Fast library on mid-range phones | 1,000-track scan < 5 s; lists scroll at 60 fps | Must |
| Reliable background playback | Plays 30+ min with screen off; notification controls work | Must |
| Persistent user library | Favorites, playlists and play history survive restart and rescan | Must |

---

## Functional Requirements

### FR-1: Audio permission
- **Description**: Request `READ_MEDIA_AUDIO` (Android 13+) or `READ_EXTERNAL_STORAGE`
  (Android 12 and older) the first time the Library tab opens, after a short explanation
  of why it is needed. "Not now" leaves the app usable.
- **Acceptance Criteria**:
  - Before the system dialog, an explanation screen states that Zema only reads audio
    files and has "Allow" and "Not now".
  - Denied or "Not now" → every library view shows the C07 empty state with a "Grant
    access" action; permanently denied → the action opens the app's system settings.
  - When access is granted (in the dialog or after returning from system settings), the
    scan starts without restarting the app.
  - On iOS, no permission is requested; the Library tab shows a C07 "Not available on
    iOS yet" state.
- **Priority**: Must

### FR-2: Library scan
- **Description**: Read audio files from Android MediaStore behind a Dart
  `LibraryScanner` interface. The first bolt spikes `on_audio_query` on the emulator; if
  it fails to build or scan on Flutter 3.47, a small Kotlin MediaStore channel replaces
  it behind the same interface. Results are stored in Drift.
- **Acceptance Criteria**:
  - Scans run on first grant, on every app start (in the background, showing the stored
    library immediately), and on manual "Rescan".
  - Audio shorter than the minimum duration (default 30 s) is excluded.
  - Tracks in hidden folders, and individually hidden tracks, are excluded from every
    list, search, album, artist, auto playlist and Play / Shuffle.
  - Folders are derived from file paths; albums and artists from file metadata; missing
    metadata shows "Unknown artist" / "Unknown album" (localized).
  - Files deleted from the phone disappear after a rescan; their entries in playlists
    and favorites are kept but hidden, and reappear if the file comes back.
  - A failed scan shows C07 error with "Try again"; the previous library stays usable.
- **Priority**: Must

### FR-3: Stable track identity
- **Description**: Each track has a Zema ID in Drift, plus its file path and a
  fingerprint (file size + duration + title). The MediaStore ID is stored only to play
  the file.
- **Acceptance Criteria**:
  - A rescan matches tracks by path first, then by fingerprint (a moved or renamed file
    keeps its ID, favorites, playlists and play counts).
  - Rebuilding the MediaStore database (new MediaStore IDs) changes no Zema IDs.
  - Covered by unit tests on the matching logic.
- **Priority**: Must

### FR-4: Library tab and Tracks (S10)
- **Description**: The Library tab has top tabs: Tracks, Folders, Albums, Artists,
  Favorites, Playlists. Tracks lists all tracks with their count.
- **Acceptance Criteria**:
  - Search-as-you-type filters by title, artist and album (case-insensitive) within
    100 ms on 1,000 tracks.
  - Sort by title, artist, album, date added or duration, ascending or descending; the
    choice is remembered.
  - Alphabet fast-scroll when sorted by title, artist or album (Latin and Ethiopic
    initials).
  - Row: art (or a placeholder), title, artist · duration; tap plays the list from that
    track.
  - Long-press starts multi-select: add to playlist, add to queue, favorite, hide.
  - Play and Shuffle buttons play the visible (filtered) list.
- **Priority**: Must

### FR-5: Folders (S11 / S11a)
- **Description**: Folders that contain audio, with song count and path; folder contents
  with breadcrumb, subfolders first, then tracks, and Play all / Shuffle.
- **Acceptance Criteria**:
  - Hide from the folder's menu removes its tracks everywhere (FR-2) and is undoable via
    a snackbar; unhide from Settings → Library → Hidden folders.
- **Priority**: Must

### FR-6: Albums (S12 / S12a)
- **Description**: Album grid sorted by name, artist or year; album detail with cover,
  name, artist, year, track count, total duration, numbered track list (by track
  number, then title), Play / Shuffle.
- **Priority**: Must

### FR-7: Artists (S13 / S13a)
- **Description**: Artist list with avatar (from one of their album covers) and song
  count; artist detail with albums and songs, Play / Shuffle.
- **Priority**: Should

### FR-8: Favorites (S14)
- **Description**: Favorited songs, newest first, with search and Play / Shuffle.
- **Acceptance Criteria**:
  - Favorite/unfavorite from the song menu, multi-select and Now Playing; the heart
    state is the same everywhere immediately.
  - Removing from the Favorites list shows an undo snackbar.
- **Priority**: Must

### FR-9: Playlists (S15–S18)
- **Description**: User playlists and three read-only auto playlists.
- **Acceptance Criteria**:
  - S15: "Create playlist" card, then user playlists (cover collage of up to 4 album
    arts, name, count), then auto playlists Recently added (30 days), Most played (top
    50) and Recently played (last 50).
  - S16: name required and unique (case-insensitive, trimmed), optional description;
    Create / Save disabled while invalid, with a message for a duplicate name.
  - S17: cover collage, name, count, total duration, Play / Shuffle; reorder by drag;
    remove by swipe with undo; menu: rename, delete (with confirmation).
  - S18: searchable list with checkboxes; songs already in the playlist are marked and
    not added twice; sticky "Add N songs" button.
  - "Change cover" is out of scope (collage only).
- **Priority**: Must

### FR-10: Playback engine
- **Description**: `just_audio` + `audio_service` playback that continues in the
  background.
- **Acceptance Criteria**:
  - Play, pause, seek, next, previous (restarts the track if > 3 s in), shuffle, repeat
    off / all / one.
  - Queue (C02): shows upcoming tracks; drag to reorder, swipe to remove, clear queue.
  - Sleep timer (C05): 15 / 30 / 45 / 60 min, end of current song, custom (1–180 min);
    shows remaining time; cancel. Playback fades out over 5 s when it ends.
  - An unplayable file is skipped with a snackbar; the queue continues.
  - Each track played for at least 30 s (or to the end, if shorter) counts once as a
    play (FR-13).
  - The last queue, track and position are restored (paused) on the next launch.
- **Priority**: Must

### FR-11: Now Playing (S08, controls only) and mini player (C01)
- **Description**: S08 shows art, title, artist, seek bar with elapsed/remaining time,
  shuffle, previous, play/pause, next, repeat, and secondary actions queue, sleep timer,
  add to playlist and favorite. The lyrics area shows "No lyrics yet". Colors come from
  the current palette (album-art colors are deferred to 003).
- **Acceptance Criteria**:
  - The mini player sits above the bottom nav on every tab while something is loaded:
    art, title, artist, play/pause, next, progress; tap opens S08; swipe down on S08
    closes it.
  - Both work in light and dark mode and with both palettes.
- **Priority**: Must

### FR-12: Song menu (C03) and add-to-playlist sheet (C04)
- **Description**: The song menu on every track row and in S08: play next, add to
  queue, add to playlist, favorite, go to album, go to artist, hide, share. View lyrics
  and edit info are not shown until later intents.
- **Acceptance Criteria**:
  - C04: "New playlist" (opens S16, then adds the song) and existing playlists with
    checkmarks; toggling adds or removes immediately.
  - Share sends the audio file through the Android share sheet.
- **Priority**: Must (share: Could)

### FR-13: Play history and counts
- **Description**: Stored in Drift; feeds Most played and Recently played.
- **Acceptance Criteria**: Counts and history survive restart and rescan (keyed by Zema
  ID).
- **Priority**: Must

### FR-14: Media notification and lock screen (C08)
- **Description**: The Android media notification and lock screen show art, title,
  artist, previous / play-pause / next and a seek bar.
- **Acceptance Criteria**: Controls work with the app in the background and the screen
  off; Bluetooth/headset media buttons work; dismissing the notification while paused
  stops the service.
- **Priority**: Must

### FR-15: Settings — Library and Playback (S28)
- **Description**: Two new Settings sections, between General and About.
- **Acceptance Criteria**:
  - Library: Hidden folders (unhide), Hidden songs (unhide), Rescan library (shows
    progress and result count), Ignore audio shorter than (off / 10 / 30 / 60 s; default
    30 s; applies on change).
  - Playback: Sleep timer default (used as the preselected option in C05), Pause when
    headphones are unplugged (default on), When another app plays sound (Pause / Lower
    volume; default Pause), Gapless playback (default on).
  - Values persist across restarts.
- **Priority**: Must (gapless: Should)

---

## Non-Functional Requirements

### Performance
| Requirement | Metric | Target |
|-------------|--------|--------|
| Library scan | 1,000 tracks, mid-range phone (release) | < 5 s |
| Stored library shown at launch | Time to first list frame after app start | < 1 s |
| List scrolling | Frame rate on 1,000-track lists | 60 fps, no jank in profile mode |
| Start playback | Tap on a track → audio | < 1 s |

### Reliability
| Requirement | Metric | Target |
|-------------|--------|--------|
| Background playback | Screen off, battery saver on | ≥ 30 min uninterrupted |
| Persistence | Favorites, playlists, history after restart and rescan | 100% retained |
| Database upgrades | Drift schema | Version 1 with a tested migration path from day one |

### Privacy
| Requirement | Metric | Target |
|-------------|--------|--------|
| Offline | Network calls | Zero |
| File access | Files modified | None (Zema never writes to audio files) |

---

## Constraints

### Technical Constraints

**Project-wide standards**: Required standards will be loaded from memory-bank standards folder by Construction Agent

**Intent-specific constraints**:
- First Drift schema; design migrations from the start (later intents add the lyrics
  cache and matches).
- Library and playback settings that are single values stay in the existing
  `SettingsRepository` (shared_preferences); hidden folders, hidden songs, favorites,
  playlists and history go in Drift.
- Player state is exposed through Riverpod providers so later intents (003 lyrics sync,
  007 detected songs) can read position and current track.
- Verified on an Android emulator with test audio files; the OEM battery-saver checks
  need a real phone.

### Business Constraints
- **Out of scope:** lyrics and lyrics status icons, accounts, cloud, edit song info
  (S09), playlist cover change, album-art background colors on S08, the global Search
  tab, iOS library access.

---

## Assumptions

| Assumption | Risk if Invalid | Mitigation |
|------------|-----------------|------------|
| `on_audio_query` builds with Flutter 3.47 and scans on Android 14 | Scan fails or doesn't build | Spike in the first bolt; fallback to a Kotlin MediaStore channel (old `MusicRepository.kt` as reference) behind `LibraryScanner` |
| OEM battery savers allow the `audio_service` foreground service | Playback killed | Test on a real Tecno/Infinix/Samsung A phone; document battery settings |
| The emulator can play test MP3s copied with `adb push` | Can't verify playback here | Use a real phone for playback checks |

---

## Open Questions

| Question | Owner | Due Date | Resolution |
|----------|-------|----------|------------|
| Stable track ID: MediaStore ID vs path+size+duration hash? | Product owner | Requirements review | Zema ID in Drift + path + fingerprint (size, duration, title); MediaStore ID only for playback (2026-10-24) |
| Album-art palette for S08 background now or in 003? | Product owner | Requirements review | Deferred to 003 (2026-10-24) |
| Test device for this intent? | Product owner | Requirements review | Android emulator; iOS shows "not available yet" (2026-10-24) |
| `on_audio_query` or a Kotlin channel? | Construction | Bolt 1 | Spike first, Kotlin fallback behind `LibraryScanner` (2026-10-24) |
