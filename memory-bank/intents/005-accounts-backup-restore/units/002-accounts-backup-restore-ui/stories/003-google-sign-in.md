---
id: 003-google-sign-in
unit: 002-accounts-backup-restore-ui
intent: 005-accounts-backup-restore
status: planned
priority: must
created: '2026-10-29T19:05:45Z'
assigned_bolt: 032-accounts-backup-restore-ui
implemented: false
---

# Story: 003-google-sign-in

## User Story

**As a** user
**I want** to sign in with my Google account
**So that** I can back up and later contribute

## Acceptance Criteria

- [ ] **Given** S24, **When** shown, **Then** the benefits, Continue with Google and Continue as guest are there
- [ ] **Given** Continue with Google, **When** the user picks an account, **Then** the ID token signs in to Supabase, the profile has the Google name and avatar, and the user goes back where they came from (or to S26 if a backup exists, from 011)
- [ ] **Given** the picker, **When** cancelled, **Then** S24 stays with no message
- [ ] **Given** no network or a failure, **When** sign-in is tried, **Then** a short message shows and the user stays a guest
- [ ] **Given** no Google client IDs in the config, **When** the app runs, **Then** sign-in buttons are hidden everywhere

## Technical Notes

- `google_sign_in` with `serverClientId` = the web client ID. Tested with the fake; the real picker is checked on the emulator once the owner adds the client IDs.

## Dependencies

### Requires
- 001-auth-repository
- 002-google-auth-config (backend)

### Enables
- 004-profile
- 011-restore-screen

## Edge Cases

| Scenario | Expected Behavior |
|----------|-------------------|
| Google account has no avatar | Letter tile |
| Signed in on another phone | Both sessions stay valid |

## Out of Scope

- Other providers
