---
id: 015-backup-additions
unit: 002-contribution-and-sync-editor-ui
intent: 006-contribution-and-sync-editor
status: complete
priority: could
created: '2026-11-02T07:00:52Z'
assigned_bolt: 052-contribution-and-sync-editor-ui
implemented: true
---

# Story: 015-backup-additions

## User Story

**As a** user changing phones
**I want** my song info edits and sync offsets in the backup
**So that** they come back on a new phone

## Acceptance Criteria

- [x] **Given** a backup, **When** made, **Then** it holds S09 overrides and per-recording sync offsets as new sections; track identity still uses the file's own tags
- [x] **Given** an older backup or app, **When** restored / reading a newer backup, **Then** it still works, ignoring what it doesn't know

## Technical Notes

- Use the 005 `extras` mechanism.

## Dependencies

### Requires
- 014-edit-song-info

### Enables
- None
