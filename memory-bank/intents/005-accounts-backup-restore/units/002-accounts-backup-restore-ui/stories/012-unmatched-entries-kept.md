---
id: 012-unmatched-entries-kept
unit: 002-accounts-backup-restore-ui
intent: 005-accounts-backup-restore
status: complete
priority: should
created: '2026-10-29T19:05:45Z'
assigned_bolt: 038-accounts-backup-restore-ui
implemented: true
---

# Story: 012-unmatched-entries-kept

## User Story

**As a** user
**I want** songs not found kept and matched later
**So that** they come back when I copy the files over

## Acceptance Criteria

- [ ] **Given** entries not found at restore, **When** restore ends, **Then** they are saved in Drift (v7) and included in the next backup
- [ ] **Given** a rescan finds a matching track, **When** the scan ends, **Then** it is added to its favorites or playlists and removed from unmatched
- [ ] **Given** sign-out or account delete, **When** done, **Then** unmatched entries are cleared
- [ ] **Given** migration v6 → v7, **When** run, **Then** existing data is kept

## Dependencies

### Requires
- 010-relink-and-merge

### Enables
- None

## Edge Cases

| Scenario | Expected Behavior |
|----------|-------------------|
| Playlist deleted locally | Its unmatched entries are dropped |

## Out of Scope

- A screen listing them beyond the restore summary
