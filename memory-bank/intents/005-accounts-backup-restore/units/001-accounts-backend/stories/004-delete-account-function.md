---
id: 004-delete-account-function
unit: 001-accounts-backend
intent: 005-accounts-backup-restore
status: planned
priority: must
created: '2026-10-29T19:05:45Z'
assigned_bolt: 030-accounts-backend
implemented: false
---

# Story: 004-delete-account-function

## User Story

**As a** signed-in user
**I want** to delete my account and backup
**So that** nothing of mine stays on the server

## Acceptance Criteria

- [ ] **Given** a signed-in user, **When** they call `delete_account()`, **Then** their auth user, profile, roles and backup are removed
- [ ] **Given** `anon`, **When** it is called, **Then** it is refused
- [ ] **Given** the user's reports (004), **When** the account is deleted, **Then** they stay, since they are anonymous
- [ ] **Given** pgTAP, **When** run, **Then** the deletion and its privileges are tested

## Technical Notes

- `security definer`, uses `auth.uid()` only, no parameters. Execute granted to `authenticated` only.

## Dependencies

### Requires
- 003-backups-table

### Enables
- 005-delete-account (ui)

## Edge Cases

| Scenario | Expected Behavior |
|----------|-------------------|
| Called twice | The second call does nothing and doesn't fail |

## Out of Scope

- Grace period / undo
