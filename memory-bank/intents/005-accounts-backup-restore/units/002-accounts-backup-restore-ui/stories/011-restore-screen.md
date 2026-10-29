---
id: 011-restore-screen
unit: 002-accounts-backup-restore-ui
intent: 005-accounts-backup-restore
status: planned
priority: must
created: '2026-10-29T19:05:45Z'
assigned_bolt: 038-accounts-backup-restore-ui
implemented: false
---

# Story: 011-restore-screen

## User Story

**As a** user on a new phone
**I want** Zema to offer my backup after I sign in
**So that** switching phones is easy

## Acceptance Criteria

- [ ] **Given** sign-in, and a cloud backup exists, **When** signed in, **Then** S26 shows 'We found your backup from <date>: N favorites, N playlists, settings'
- [ ] **Given** S26, **When** Restore, **Then** the merge runs with progress, then a summary of what was restored and the songs not found
- [ ] **Given** S26, **When** Start fresh, **Then** nothing changes locally and the cloud backup stays
- [ ] **Given** S25b, **When** Restore, **Then** S26 opens
- [ ] **Given** the emulator, **When** phone A backup → wiped emulator restore, **Then** same favorites, playlists, choices and settings

## Dependencies

### Requires
- 010-relink-and-merge
- 008-backup-now

### Enables
- None

## Edge Cases

| Scenario | Expected Behavior |
|----------|-------------------|
| Library not scanned yet | Restore waits for the scan, then matches |

## Out of Scope

- Restoring onto a different account
