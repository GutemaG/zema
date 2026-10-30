---
id: 007-backup-document
unit: 002-accounts-backup-restore-ui
intent: 005-accounts-backup-restore
status: complete
priority: must
created: '2026-10-29T19:05:45Z'
assigned_bolt: 034-accounts-backup-restore-ui
implemented: true
---

# Story: 007-backup-document

## User Story

**As a** app
**I want** a versioned backup document built from the database and settings
**So that** backups are small, readable and can grow later

## Acceptance Criteria

- [ ] **Given** `zema_core`, **When** read, **Then** `BackupDocument` (format 1) holds favorites, playlists, hand-made lyrics choices, hidden folders and songs, settings, and unmatched entries; tracks as `TrackIdentity` (title, artist, album, duration ms, file name)
- [ ] **Given** a document, **When** encoded and decoded, **Then** it round-trips exactly; unknown sections and newer fields are kept or ignored, not fatal
- [ ] **Given** a format newer than the app knows, **When** decoded, **Then** a clear error says to update the app
- [ ] **Given** 1,000 favorites + 50 playlists × 100 songs, **When** encoded, **Then** the JSON is under 1 MB
- [ ] **Given** the app, **When** a document is built, **Then** it reads Drift and preferences and contains no paths except the file name, no audio and no play history

## Technical Notes

- Pure Dart in `zema_core`; the builder in the app.

## Dependencies

### Requires
- None

### Enables
- 008-backup-now
- 010-relink-and-merge

## Edge Cases

| Scenario | Expected Behavior |
|----------|-------------------|
| Track with no artist | Identity keeps null |

## Out of Scope

- Encryption beyond Supabase at rest
