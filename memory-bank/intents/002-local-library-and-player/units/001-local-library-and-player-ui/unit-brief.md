---
unit: 001-local-library-and-player-ui
intent: 002-local-library-and-player
unit_type: frontend
default_bolt_type: simple-construction-bolt
phase: inception
status: stories-defined
created: 2026-10-24T19:21:00Z
updated: 2026-10-24T19:21:00Z
---

# Unit Brief: Local Library and Player UI

## Purpose

Turn the "Coming soon" Library tab into a complete offline music player for the phone's
audio files: scan, browse, organize (favorites, playlists, hidden items) and play in the
background with system controls. Later intents add lyrics (003), backup (005) and
detected songs (007) on top of the models and providers built here.

## Scope

### In Scope
- `LibraryScanner` interface with an `on_audio_query` spike and a Kotlin MediaStore fallback
- The first Drift database (schema v1, migration test harness)
- `Track` model, fingerprint and rescan reconciliation in `zema_core`
- Audio permission flow with explanation, "Not now", and the C07 states
- Scan pipeline: minimum duration, hidden folders and songs, deleted files, background rescan on launch
- Library tab: Tracks, Folders, Albums, Artists, Favorites, Playlists
- Playback engine (`just_audio` + `audio_service`): queue, shuffle, repeat, error skip, restore last queue
- Mini player (C01), Now Playing (S08, controls only), queue (C02), sleep timer (C05)
- Media notification and lock screen (C08), headset buttons, audio focus, becoming-noisy
- Song menu (C03), add-to-playlist sheet (C04), multi-select
- Play history and counts; auto playlists Recently added, Most played, Recently played
- Settings: Library and Playback sections
- iOS: Library tab shows "not available on iOS yet"

### Out of Scope
- Lyrics, lyrics status icons, view lyrics / edit info in the song menu (003, later)
- Album-art background colors on S08 (003)
- Edit song info S09, playlist cover change, the global Search tab
- Accounts, cloud, backup (004+)
- iOS library access
- Translating new strings into am/om/ti (English fallback is acceptable)

---

## Assigned Requirements

| FR | Requirement | Priority |
|----|-------------|----------|
| FR-1 | Audio permission | Must |
| FR-2 | Library scan | Must |
| FR-3 | Stable track identity | Must |
| FR-4 | Library tab and Tracks (S10) | Must |
| FR-5 | Folders (S11 / S11a) | Must |
| FR-6 | Albums (S12 / S12a) | Must |
| FR-7 | Artists (S13 / S13a) | Should |
| FR-8 | Favorites (S14) | Must |
| FR-9 | Playlists (S15–S18) | Must |
| FR-10 | Playback engine | Must |
| FR-11 | Now Playing (S08) and mini player (C01) | Must |
| FR-12 | Song menu (C03) and add-to-playlist (C04) | Must |
| FR-13 | Play history and counts | Must |
| FR-14 | Media notification and lock screen (C08) | Must |
| FR-15 | Settings: Library and Playback | Must |

---

## Domain Concepts

### Key Entities
| Entity | Description | Attributes |
|--------|-------------|------------|
| `ScannedAudio` | One MediaStore entry as returned by the scanner | mediaStoreId, uri, path, title, artist, album, trackNumber, year, durationMs, sizeBytes, dateAdded |
| `Track` | A track as Zema knows it (`zema_core`) | id (Zema), mediaStoreId, uri, path, folder, title, artist, album, trackNumber, year, duration, size, dateAdded, missing |
| `TrackFingerprint` | Re-linking key when a path changes | size, duration (rounded to 1 s), normalized title |
| `HiddenFolder` / `HiddenTrack` | Excluded from every view | path / trackId |
| `Favorite` | A favorited track | trackId, addedAt |
| `Playlist` | A user playlist | id, name (unique, case-insensitive), description, createdAt, updatedAt |
| `PlaylistEntry` | A track at a position in a playlist | playlistId, trackId, position |
| `PlayEvent` | One counted play | trackId, playedAt |
| `PlayerState` | What the player is doing (Riverpod) | queue, index, position, playing, shuffle, repeat, sleepTimer |

### Key Operations
| Operation | Description | Inputs | Outputs |
|-----------|-------------|--------|---------|
| `LibraryScanner.scan` | Read all audio from MediaStore | — | `List<ScannedAudio>` |
| `reconcileTracks` | Match a scan to stored tracks (path, then fingerprint) | stored tracks, scan | inserts, updates, moved, missing |
| `LibraryRepository.sync` | Apply a reconciliation in one transaction | scan, min duration | counts |
| `PlayerController.playList` | Replace the queue and start at an index | tracks, start index, shuffle? | — |
| `PlayerController.playNext / addToQueue` | Insert into the queue | tracks | — |
| `recordPlay` | Count a play after 30 s (or at the end) | trackId | — |

---

## Story Summary

| Metric | Count |
|--------|-------|
| Total Stories | 21 |
| Must Have | 20 |
| Should Have | 1 |
| Could Have | 0 |

### Stories

| Story ID | Title | Priority | Status |
|----------|-------|----------|--------|
| 001-library-scanner-spike | Library scanner spike and interface | Must | Complete |
| 002-library-database | Drift library database and track identity | Must | Complete |
| 003-audio-permission | Audio permission | Must | Complete |
| 004-library-scan-and-sync | Library scan and sync | Must | Complete |
| 005-library-tab-and-tracks | Library tab and Tracks | Must | Complete |
| 006-playback-engine | Playback engine | Must | Complete |
| 007-mini-player-and-now-playing | Mini player and Now Playing | Must | Complete |
| 008-media-notification | Media notification, lock screen and headset | Must | Complete |
| 009-queue-sheet | Queue sheet | Must | Complete |
| 010-sleep-timer | Sleep timer | Must | Complete |
| 011-folders | Folders | Must | Complete |
| 012-albums | Albums | Must | Complete |
| 013-artists | Artists | Should | Complete |
| 014-favorites | Favorites | Must | Complete |
| 015-playlists | Playlists | Must | Complete |
| 016-add-songs-picker | Add songs picker | Must | Complete |
| 017-song-menu-and-add-to-playlist | Song menu and add-to-playlist sheet | Must | Complete |
| 018-track-multi-select | Track multi-select | Must | Planned |
| 019-play-history-and-auto-playlists | Play history and auto playlists | Must | Planned |
| 020-library-settings | Library settings | Must | Planned |
| 021-playback-settings | Playback settings | Must | Planned |

---

## Dependencies

### Depends On
| Unit | Reason |
|------|--------|
| 001-app-foundation-ui (intent 001) | Shell, router, theme tokens, l10n, C07, `SettingsRepository` |

### Depended By
| Unit | Reason |
|------|--------|
| Intent 003 lyrics unit | Now Playing, player position provider |
| Intent 005 backup unit | Track fingerprint for re-linking |
| Intent 007 detection unit | Mini player in view-only mode |

### External Dependencies
| System | Purpose | Risk |
|--------|---------|------|
| `on_audio_query` | MediaStore scan and album art | High (unreleased since 2023; spike in bolt 004) |
| `just_audio` / `audio_service` / `audio_session` | Playback, media session, focus | Medium (OEM battery savers) |
| `permission_handler` | Audio permission | Low |
| `drift` / `drift_flutter` | SQLite database | Low |
| `share_plus` | Share a file | Low |
| Android emulator + `adb push` test files | Verification here | Low |

---

## Technical Context

### Suggested Technology
Per `standards/tech-stack.md`: `drift` + `drift_dev` + `build_runner` (generated
`*.g.dart` committed or generated in CI, decided in bolt 004), `drift_flutter` for the
connection, `just_audio`, `audio_service`, `audio_session`, `permission_handler`,
`on_audio_query` (spike), `share_plus`, `path`. Test MP3s generated with `ffmpeg`
(sine tones with ID3 tags, Latin and Ethiopic titles), never committed if large.

### Integration Points
| Integration | Type | Protocol |
|-------------|------|----------|
| MediaStore | Device data | Plugin or `MethodChannel` `com.zemaapp.zema/library` |
| Android media session | System service | `audio_service` |
| Permissions | System | `permission_handler` |

### Data Storage
| Data | Type | Volume | Retention |
|------|------|--------|-----------|
| Tracks, hidden items, favorites, playlists, entries, play events | Drift (SQLite) | ~1–10k tracks, unbounded events (pruned to 1 year) | Until app data cleared |
| Min duration, sorts, playback options, last queue | shared_preferences | ~10 keys | Until app data cleared |

---

## Constraints

- Feature code must not import another feature's `data/` layer: player and library share
  models through `zema_core` and providers in `application/`.
- No `Color(0x…)` literals outside `lib/app/theme/`; no user-visible string literals.
- The UI never touches the scanner or Drift directly; it reads Riverpod providers.
- Tests use `NativeDatabase.memory()`, a `FakeLibraryScanner` and a fake audio handler.
- iOS build must keep compiling (`flutter build ios --no-codesign` passes).

---

## Success Criteria

### Functional
- [ ] Permission → scan → Tracks on the emulator with test files
- [ ] Play a track; it keeps playing with the screen off and from the notification
- [ ] Favorites, playlists and play counts survive restart and rescan, and a moved file keeps them
- [ ] All library tabs, song menu, queue and sleep timer work as specified

### Non-Functional
- [ ] 1,000-track scan < 5 s (release, mid-range phone); 60 fps scrolling
- [ ] Stored library on screen < 1 s after launch; tap → audio < 1 s
- [ ] ≥ 30 min background playback (real phone)
- [ ] Zero network calls; audio files never modified

### Quality
- [ ] `flutter analyze` zero issues; `dart format` clean
- [ ] Unit tests for reconciliation, fingerprint, queue logic, play counting
- [ ] Drift tests for every DAO and the schema v1 migration harness
- [ ] Widget tests for each screen in loading, empty, error and data states, light and dark, at 1.3× text

---

## Bolt Suggestions

| Bolt | Type | Stories | Objective |
|------|------|---------|-----------|
| 004-local-library-and-player-ui | simple | 001, 002, 003, 004 | Scanner spike, database, permission, scan + sync |
| 005-local-library-and-player-ui | simple | 005, 006, 007, 008 | Tracks list and playback end to end |
| 006-local-library-and-player-ui | simple | 009, 010, 011, 012, 013 | Queue, sleep timer, folders, albums, artists |
| 007-local-library-and-player-ui | simple | 014, 015, 016, 017 | Favorites, playlists, song menu |
| 008-local-library-and-player-ui | simple | 018, 019, 020, 021 | Multi-select, history, settings |

---

## Notes

- No Android emulator exists yet: bolt 004 creates one from the installed SDK system
  image and pushes generated test files with `adb push` into `/sdcard/Music/…`.
- The old `MusicRepository.kt` (see `docs/flutter-build-notes.md`) is the reference for
  the Kotlin fallback.
