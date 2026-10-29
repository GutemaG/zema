---
id: 009-auto-backup
unit: 002-accounts-backup-restore-ui
intent: 005-accounts-backup-restore
status: planned
priority: must
created: '2026-10-29T19:05:45Z'
assigned_bolt: 036-accounts-backup-restore-ui
implemented: false
---

# Story: 009-auto-backup

## User Story

**As a** signed-in user
**I want** my data backed up daily without thinking
**So that** a lost phone doesn't lose my playlists

## Acceptance Criteria

- [ ] **Given** Auto backup on (default after sign-in), **When** Android, app closed, on Wi-Fi, **Then** a WorkManager task backs up at most once a day
- [ ] **Given** iOS, **When** the app opens and the last backup is over 24 h old, **Then** it backs up on Wi-Fi; background fetch also tries
- [ ] **Given** Auto backup off, signed out, or on mobile data, **When** the task runs, **Then** nothing is uploaded
- [ ] **Given** nothing changed since the last backup, **When** the task runs, **Then** nothing is uploaded
- [ ] **Given** the emulator, **When** checked with the app closed (forced run), **Then** a backup lands

## Technical Notes

- `workmanager` plugin with a network-type unmetered constraint. A hash of the document skips unchanged backups.

## Dependencies

### Requires
- 008-backup-now

### Enables
- None

## Edge Cases

| Scenario | Expected Behavior |
|----------|-------------------|
| Phone restarts | Task survives |
| Vendor kills background work | On-open backup after 24 h covers it |

## Out of Scope

- Real-time sync
