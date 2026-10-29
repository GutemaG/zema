---
id: 001-profiles-and-roles
unit: 001-accounts-backend
intent: 005-accounts-backup-restore
status: complete
priority: must
created: '2026-10-29T19:05:45Z'
assigned_bolt: 029-accounts-backend
implemented: true
---

# Story: 001-profiles-and-roles

## User Story

**As a** new user
**I want** a profile made for me when I first sign in
**So that** the app can show my name and role

## Acceptance Criteria

- [ ] **Given** a new row in `auth.users` with Google metadata, **When** it is inserted, **Then** a `profiles` row is made with the display name (trimmed, cut to 40) and avatar URL, and `contributor` is added in `user_roles`
- [ ] **Given** a signed-in user, **When** they read `profiles` or `user_roles`, **Then** they see only their own rows; `anon` sees none
- [ ] **Given** a signed-in user, **When** they update their own `display_name` to 1–40 characters, **Then** it is saved; empty, longer or other columns are refused
- [ ] **Given** a signed-in user, **When** they try to insert, update or delete roles, or another user's profile, **Then** it is refused
- [ ] **Given** pgTAP, **When** run, **Then** the trigger, RLS and the name limits are tested

## Technical Notes

- Trigger is `security definer` on `auth.users` insert. Name falls back to the email's local part when Google gives none. Test users are inserted in rolled-back transactions; `set local role authenticated` with `request.jwt.claims` acts as them.

## Dependencies

### Requires
- None

### Enables
- 003-backups-table
- 001-auth-repository (ui)

## Edge Cases

| Scenario | Expected Behavior |
|----------|-------------------|
| Google gives no name | The email's local part is used |
| Name of only spaces | Refused |

## Out of Scope

- Role changes (006/008); profile stats (006)
