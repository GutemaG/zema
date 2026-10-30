---
id: 010-relink-and-merge
unit: 002-accounts-backup-restore-ui
intent: 005-accounts-backup-restore
status: complete
priority: must
created: '2026-10-29T19:05:45Z'
assigned_bolt: 037-accounts-backup-restore-ui
implemented: true
---

# Story: 010-relink-and-merge

## User Story

**As a** user on a new phone
**I want** my favorites and playlists matched to my songs here
**So that** I don't rebuild them by hand

## Acceptance Criteria

- [ ] **Given** `zema_core` matcher, **When** given identities and this phone's tracks, **Then** it matches by file name + duration ±2 s, then normalized title + artist + duration ±2 s, never title alone
- [ ] **Given** the merge, **When** run, **Then** favorites are added, same-name playlists get missing songs at the end, others are created, hand-made lyrics choices are added only where none exist, and settings are applied
- [ ] **Given** an error midway, **When** merge runs, **Then** nothing on the phone changes (one transaction)
- [ ] **Given** 2,000 entries against 5,000 tracks, **When** matched, **Then** under 2 s (timed test)
- [ ] **Given** the same files on a new phone, **When** restored, **Then** ≥ 95% matched (test fixture with realistic names)

## Technical Notes

- Normalization reuses `zema_core` search normalization where it fits.

## Dependencies

### Requires
- 007-backup-document

### Enables
- 011-restore-screen
- 012-unmatched-entries-kept

## Edge Cases

| Scenario | Expected Behavior |
|----------|-------------------|
| Two tracks match one identity | Prefer file name match, then the closest duration |

## Out of Scope

- Fuzzy matching beyond normalization; manual re-link
