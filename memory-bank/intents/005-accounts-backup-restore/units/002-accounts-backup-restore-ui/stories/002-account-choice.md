---
id: 002-account-choice
unit: 002-accounts-backup-restore-ui
intent: 005-accounts-backup-restore
status: planned
priority: must
created: '2026-10-29T19:05:45Z'
assigned_bolt: 032-accounts-backup-restore-ui
implemented: false
---

# Story: 002-account-choice

## User Story

**As a** new or existing user
**I want** to choose guest or sign in once
**So that** I'm not pushed into an account

## Acceptance Criteria

- [ ] **Given** the first launch after this update, **When** the app opens, **Then** S04 shows before Home, with Continue as guest as the main button and what an account adds
- [ ] **Given** S04, **When** Continue as guest, **Then** Home opens and S04 never shows again
- [ ] **Given** S04, **When** Sign in, **Then** S24 opens; cancelling there also goes to Home and S04 doesn't return
- [ ] **Given** a build where sign-in is unavailable, **When** the app opens, **Then** S04 is skipped
- [ ] **Given** 1.3× text, light and dark, **When** shown, **Then** it fits

## Technical Notes

- A preference `accountChoiceShown`. A go_router redirect before Home.

## Dependencies

### Requires
- 001-auth-repository

### Enables
- 003-google-sign-in

## Edge Cases

| Scenario | Expected Behavior |
|----------|-------------------|
| App killed on S04 | S04 shows again next time |

## Out of Scope

- Onboarding S01–S03
