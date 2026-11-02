---
id: 014-edit-song-info
unit: 002-contribution-and-sync-editor-ui
intent: 006-contribution-and-sync-editor
status: complete
priority: should
created: '2026-11-02T07:00:52Z'
assigned_bolt: 052-contribution-and-sync-editor-ui
implemented: true
---

# Story: 014-edit-song-info

## User Story

**As a** listener
**I want** to fix a local file's title, artist, album, track number and cover
**So that** my library and lyrics matching are right

## Acceptance Criteria

- [x] **Given** Song detail's overflow or the track menu, **When** Edit song info, **Then** S09 shows the fields and a cover picker
- [x] **Given** saved changes, **When** anywhere the track is shown, sorted or searched, and in lyrics matching, **Then** the overrides are used; the file is never written
- [x] **Given** Reset to file's info, **When** pressed, **Then** the overrides are removed

## Technical Notes

- Drift overrides table; apply in the library DAO's queries.

## Dependencies

### Requires
- None

### Enables
- 015-backup-additions

## Edge Cases

| Scenario | Expected Behavior |
|----------|-------------------|
| Empty title | Not allowed |

## Out of Scope

- Writing tags into files
