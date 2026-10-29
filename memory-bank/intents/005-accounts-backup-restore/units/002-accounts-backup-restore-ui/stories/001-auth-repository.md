---
id: 001-auth-repository
unit: 002-accounts-backup-restore-ui
intent: 005-accounts-backup-restore
status: complete
priority: must
created: '2026-10-29T19:05:45Z'
assigned_bolt: 031-accounts-backup-restore-ui
implemented: true
---

# Story: 001-auth-repository

## User Story

**As a** app
**I want** one interface for sign-in and profile, with a Supabase version and a fake
**So that** screens never talk to Supabase directly and can be tested offline

## Acceptance Criteria

- [ ] **Given** `zema_core`, **When** read, **Then** `AuthRepository` (current user stream, `signInWithGoogleIdToken`, `signOut`) and `ProfileRepository` (get, rename, roles) are defined, with an `Account` model
- [ ] **Given** `zema_data`, **When** used against the local backend, **Then** it signs in with a test token path, reads the profile and roles, renames, and signs out
- [ ] **Given** the session, **When** the app restarts, **Then** it is restored from secure storage and refreshed; an unrefreshable session gives the guest state
- [ ] **Given** a build with no backend, **When** the app runs, **Then** the account provider says sign-in is unavailable
- [ ] **Given** a fake, **When** used in tests, **Then** it signs in, fails and cancels on demand

## Technical Notes

- Supabase `Session` persisted through a `flutter_secure_storage`-backed `LocalStorage`. The Google token step itself is in story 003; here a test-only email sign-in on the local backend stands in for it in integration tests.

## Dependencies

### Requires
- 001-profiles-and-roles (backend)

### Enables
- 002-account-choice
- 003-google-sign-in
- 004-profile

## Edge Cases

| Scenario | Expected Behavior |
|----------|-------------------|
| Clock skew makes a token look expired | Refresh is attempted before signing out |

## Out of Scope

- The Google picker (003)
