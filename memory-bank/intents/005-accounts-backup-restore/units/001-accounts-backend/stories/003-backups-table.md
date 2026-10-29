---
id: 003-backups-table
unit: 001-accounts-backend
intent: 005-accounts-backup-restore
status: complete
priority: must
created: '2026-10-29T19:05:45Z'
assigned_bolt: 030-accounts-backend
implemented: true
---

# Story: 003-backups-table

## User Story

**As a** signed-in user
**I want** one private backup stored on the server
**So that** I can restore it on another phone

## Acceptance Criteria

- [ ] **Given** a signed-in user, **When** they upsert their row in `backups` with a document, format version and device name, **Then** it is stored, with `updated_at` set by the server
- [ ] **Given** a document over 2 MB, **When** written, **Then** it is refused with a recognisable error
- [ ] **Given** another user's row, or `anon`, **When** read or written, **Then** nothing is visible and writes are refused
- [ ] **Given** pgTAP, **When** run, **Then** RLS, the size limit and upsert are tested

## Technical Notes

- `backups(user_id uuid primary key references auth.users on delete cascade, format int, document jsonb, size_bytes int, device text, updated_at timestamptz)`. Size checked by `octet_length(document::text)` in a check or trigger.

## Dependencies

### Requires
- 001-profiles-and-roles

### Enables
- 004-delete-account-function
- 008-backup-now (ui)

## Edge Cases

| Scenario | Expected Behavior |
|----------|-------------------|
| Two phones back up at once | Last write wins; one row only |

## Out of Scope

- Backup history; partial sync
