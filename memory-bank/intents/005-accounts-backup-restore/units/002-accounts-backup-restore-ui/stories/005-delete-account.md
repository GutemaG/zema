---
id: 005-delete-account
unit: 002-accounts-backup-restore-ui
intent: 005-accounts-backup-restore
status: planned
priority: must
created: '2026-10-29T19:05:45Z'
assigned_bolt: 033-accounts-backup-restore-ui
implemented: false
---

# Story: 005-delete-account

## User Story

**As a** signed-in user
**I want** to delete my account from Profile
**So that** I control my data

## Acceptance Criteria

- [ ] **Given** Profile, **When** Delete account, **Then** a first dialog names what will be deleted (account, profile, cloud backup) and keeps local data
- [ ] **Given** the second confirmation, **When** confirmed online, **Then** `delete_account` runs, the phone signs out and Google is disconnected
- [ ] **Given** offline, **When** tried, **Then** a message shows and nothing changes
- [ ] **Given** the emulator, **When** checked, **Then** the user's rows are gone on the local backend

## Technical Notes

- Second step: type nothing, just a red Delete button after a short explanation.

## Dependencies

### Requires
- 004-profile
- 004-delete-account-function (backend)

### Enables
- None

## Edge Cases

| Scenario | Expected Behavior |
|----------|-------------------|
| Server error | Message; still signed in |

## Out of Scope

- Deleting local data
