---
id: 006-guest-prompt-and-entry-points
unit: 002-accounts-backup-restore-ui
intent: 005-accounts-backup-restore
status: complete
priority: must
created: '2026-10-29T19:05:45Z'
assigned_bolt: 034-accounts-backup-restore-ui
implemented: true
---

# Story: 006-guest-prompt-and-entry-points

## User Story

**As a** guest
**I want** a short explanation when something needs an account
**So that** I understand why and can choose

## Acceptance Criteria

- [ ] **Given** a guest, **When** they open Settings → Account & backup, **Then** the C09 sheet says why an account is needed, with Sign in and Not now
- [ ] **Given** C09, **When** Not now, **Then** it closes with no change
- [ ] **Given** C09, **When** Sign in, **Then** S24 opens and returns to where the guest was
- [ ] **Given** the app, **When** any player, library, search or lyrics action, **Then** no sign-in prompt appears (widget tests over the main screens)
- [ ] **Given** a signed-in user, **When** they open Settings → Account & backup, **Then** S25b opens

## Technical Notes

- C09 is a reusable `showSignInPrompt(context, reason)` for 006.

## Dependencies

### Requires
- 004-profile

### Enables
- Intent 006 contribute

## Edge Cases

| Scenario | Expected Behavior |
|----------|-------------------|
| Sign-in unavailable | Account & backup is hidden |

## Out of Scope

- Contribute tab content (006)
