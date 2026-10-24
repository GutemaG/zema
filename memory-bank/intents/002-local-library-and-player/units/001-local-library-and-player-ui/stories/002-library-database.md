---
id: 002-library-database
unit: 001-local-library-and-player-ui
intent: 002-local-library-and-player
status: complete
priority: must
created: 2026-10-24T19:22:00Z
assigned_bolt: 004-local-library-and-player-ui
implemented: true
---

# Story: 002-library-database

## User Story

**As a** listener
**I want** my favorites, playlists and play counts to stay attached to the right songs
**So that** moving or rescanning files never breaks what I built

## Acceptance Criteria

- [ ] **Given** a fresh install, **When** the app starts, **Then** a Drift database at schema version 1 is created with tables: tracks, hidden_folders, hidden_tracks, favorites, playlists, playlist_entries, play_events
- [ ] **Given** a stored library and a new scan, **When** `reconcileTracks` runs, **Then** tracks are matched by path first, then by fingerprint (size + duration rounded to 1 s + normalized title); matched tracks keep their Zema ID and their metadata is updated
- [ ] **Given** a file moved to another folder, **When** reconciled, **Then** it keeps its Zema ID, favorites, playlist entries and play events
- [ ] **Given** MediaStore IDs that all changed (database rebuild), **When** reconciled, **Then** no Zema ID changes
- [ ] **Given** a stored track missing from the scan, **When** reconciled, **Then** it is marked `missing` (not deleted) and comes back with the same ID if the file returns
- [ ] **Given** two stored tracks with the same fingerprint, **When** a moved file matches both, **Then** it is treated as new (no wrong re-link)
- [ ] **Given** tests, **When** run, **Then** `reconcileTracks` is unit-tested in `zema_core` (including Ethiopic titles), and DAOs and the migration harness are tested with `NativeDatabase.memory()`

## Technical Notes

- `Track`, `TrackFingerprint`, `reconcileTracks` live in `packages/zema_core/lib/src/library/` (pure Dart). Drift tables and DAOs in `apps/mobile/lib/app/database/`.
- Zema ID: an auto-increment integer or UUID; decide in the plan stage (UUID is easier for backup in 005).
- Set up `drift_dev` schema dumps (`drift_schemas/`) and a generated migration test from version 1, so later intents add migrations safely.
- Delete cascades: removing a playlist deletes its entries; tracks are never hard-deleted in this intent.

## Dependencies

### Requires
- 001-library-scanner-spike

### Enables
- 004-library-scan-and-sync
- 014-favorites
- 015-playlists
- 019-play-history-and-auto-playlists

## Edge Cases

| Scenario | Expected Behavior |
|----------|-------------------|
| Database file corrupt | Logged as SEVERE; the app shows C07 error rather than crashing |
| Title normalization | Trim, lowercase, collapse spaces; Ethiopic kept as is |

## Out of Scope

- Backup/export (005)
- Lyrics cache tables (003)
