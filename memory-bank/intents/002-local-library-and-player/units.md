---
intent: 002-local-library-and-player
phase: inception
status: units-decomposed
updated: 2026-10-24T19:21:00Z
---

# Local Library and Player - Unit Decomposition

## Units Overview

Project type `frontend-app` → backend units disabled, one feature-based frontend unit
(`{intent}-ui`, simple-construction-bolt). Pure-Dart library logic (track
reconciliation, library models) goes into `packages/zema_core` as part of the same unit.
This intent decomposes into **1 unit**:

### Unit 1: 001-local-library-and-player-ui

**Description**: The offline music library and player in `apps/mobile`: the
`LibraryScanner` (on_audio_query or Kotlin MediaStore channel), the first Drift
database, audio permission, the Library tab with Tracks / Folders / Albums / Artists /
Favorites / Playlists, the playback engine with queue and sleep timer, mini player and
Now Playing, the media notification, the song menu and add-to-playlist sheet, and the
Library and Playback sections in Settings.

**Stories**:

- 001-library-scanner-spike
- 002-library-database
- 003-audio-permission
- 004-library-scan-and-sync
- 005-library-tab-and-tracks
- 006-playback-engine
- 007-mini-player-and-now-playing
- 008-media-notification
- 009-queue-sheet
- 010-sleep-timer
- 011-folders
- 012-albums
- 013-artists
- 014-favorites
- 015-playlists
- 016-add-songs-picker
- 017-song-menu-and-add-to-playlist
- 018-track-multi-select
- 019-play-history-and-auto-playlists
- 020-library-settings
- 021-playback-settings

**Deliverables**:

- `apps/mobile/lib/features/library/{data,application,presentation}/`
- `apps/mobile/lib/features/player/{data,application,presentation}/`
- `apps/mobile/lib/shared/widgets/` (C01 mini player, C03 song menu, C04 sheet, track row, art)
- `apps/mobile/lib/app/database/` (Drift database, schema v1, migration tests)
- `packages/zema_core/lib/src/library/` (Track model, fingerprint, reconciliation)
- Kotlin `MediaStore` channel only if the spike fails
- New Settings sections; ARB strings in en (am/om/ti fall back to English)
- Unit, Drift, widget tests; emulator checks

**Dependencies**:

- Depends on: `001-app-foundation-ui` (intent 001: shell, theme, l10n, C07, settings)
- Depended by: intents 003 (lyrics on Now Playing), 005 (backup re-linking by
  fingerprint), 007 (mini player for detected songs)

**Estimated Complexity**: L

## Requirement-to-Unit Mapping

- **FR-1** Audio permission → `001-local-library-and-player-ui`
- **FR-2** Library scan → `001-local-library-and-player-ui`
- **FR-3** Stable track identity → `001-local-library-and-player-ui`
- **FR-4** Library tab and Tracks (S10) → `001-local-library-and-player-ui`
- **FR-5** Folders (S11 / S11a) → `001-local-library-and-player-ui`
- **FR-6** Albums (S12 / S12a) → `001-local-library-and-player-ui`
- **FR-7** Artists (S13 / S13a) → `001-local-library-and-player-ui`
- **FR-8** Favorites (S14) → `001-local-library-and-player-ui`
- **FR-9** Playlists (S15–S18) → `001-local-library-and-player-ui`
- **FR-10** Playback engine → `001-local-library-and-player-ui`
- **FR-11** Now Playing and mini player → `001-local-library-and-player-ui`
- **FR-12** Song menu and add-to-playlist → `001-local-library-and-player-ui`
- **FR-13** Play history and counts → `001-local-library-and-player-ui`
- **FR-14** Media notification and lock screen → `001-local-library-and-player-ui`
- **FR-15** Settings: Library and Playback → `001-local-library-and-player-ui`

## Unit Dependency Graph

```text
[001-app-foundation-ui] (intent 001, complete)
            │
            ▼
[001-local-library-and-player-ui]
```

## Execution Order

1. Bolt 004: scanner spike, Drift database, permission, scan + sync (stories 001–004)
2. Bolt 005: Tracks, playback engine, mini player + Now Playing, notification (005–008)
3. Bolt 006: queue, sleep timer, folders, albums, artists (009–013)
4. Bolt 007: favorites, playlists, add-songs picker, song menu + C04 (014–017)
5. Bolt 008: multi-select, history + auto playlists, Library and Playback settings (018–021)
