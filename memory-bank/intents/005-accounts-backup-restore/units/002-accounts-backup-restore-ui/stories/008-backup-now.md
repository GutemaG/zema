---
id: 008-backup-now
unit: 002-accounts-backup-restore-ui
intent: 005-accounts-backup-restore
status: complete
priority: must
created: '2026-10-29T19:05:45Z'
assigned_bolt: 035-accounts-backup-restore-ui
implemented: true
---

# Story: 008-backup-now

## User Story

**As a** signed-in user
**I want** to back up now and see when I last did
**So that** I know my data is safe

## Acceptance Criteria

- [ ] **Given** S25b, **When** shown, **Then** last backup time (or Never), the last error if any, an Auto backup toggle, Back up now and Restore
- [ ] **Given** Back up now, **When** online, **Then** the document is uploaded and the time updates
- [ ] **Given** Back up now, **When** offline or failing, **Then** a message shows; the cloud copy is unchanged
- [ ] **Given** a cloud backup from another phone after Start fresh, **When** Back up now, **Then** a warning asks before replacing it
- [ ] **Given** the emulator, **When** checked, **Then** the row on the local backend matches the phone's data

## Technical Notes

- `BackupRepository` in `zema_core`, Supabase upsert in `zema_data`.

## Dependencies

### Requires
- 007-backup-document
- 003-backups-table (backend)

### Enables
- 009-auto-backup
- 011-restore-screen

## Edge Cases

| Scenario | Expected Behavior |
|----------|-------------------|
| Document over 2 MB | Message; nothing uploaded |

## Out of Scope

- Backup history
