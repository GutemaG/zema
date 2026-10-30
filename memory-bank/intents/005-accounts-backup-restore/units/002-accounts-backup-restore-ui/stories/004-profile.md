---
id: 004-profile
unit: 002-accounts-backup-restore-ui
intent: 005-accounts-backup-restore
status: complete
priority: must
created: '2026-10-29T19:05:45Z'
assigned_bolt: 033-accounts-backup-restore-ui
implemented: true
---

# Story: 004-profile

## User Story

**As a** user
**I want** a Profile screen from Home
**So that** I can see and change my account and reach Settings

## Acceptance Criteria

- [x] **Given** Home, **When** shown, **Then** the header has my avatar (or a guest icon) that opens S25; Settings moves into Profile
- [x] **Given** S25 signed in, **When** shown, **Then** avatar, name, role badge, and links to Backup & sync, Settings and Sign out
- [x] **Given** the name, **When** edited to 1–40 characters, **Then** it is saved to the server; offline, a message shows and the old name stays
- [x] **Given** Sign out, **When** confirmed, **Then** the guest state shows, local data is kept, and auto backup stops
- [x] **Given** S25 as a guest, **When** shown, **Then** guest icon, a sign-in card, and Settings
- [x] **Given** offline, **When** S25 opens, **Then** the cached avatar and name show

## Technical Notes

- Avatar cached with the image cache; letter tile fallback reuses `LetterTile`.

## Dependencies

### Requires
- 003-google-sign-in

### Enables
- 005-delete-account
- 008-backup-now

## Edge Cases

| Scenario | Expected Behavior |
|----------|-------------------|
| Long name at 1.3× text | Ellipsis, no overflow |

## Out of Scope

- Stats and My contributions (006)
