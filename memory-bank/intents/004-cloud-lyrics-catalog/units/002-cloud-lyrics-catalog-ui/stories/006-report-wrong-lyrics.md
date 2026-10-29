---
id: 006-report-wrong-lyrics
unit: 002-cloud-lyrics-catalog-ui
intent: 004-cloud-lyrics-catalog
status: complete
priority: should
created: '2026-10-29T05:59:04Z'
assigned_bolt: 027-cloud-lyrics-catalog-ui
implemented: true
---

# Story: 006-report-wrong-lyrics

## User Story

**As a** listener
**I want** to report lyrics that are wrong
**So that** they get fixed for everyone

## Acceptance Criteria

- [x] **Given** Song detail or the Now Playing lyrics options, **When** I choose Report wrong lyrics, **Then** a sheet asks for a reason (wrong words, wrong timing, wrong song, other) and an optional note
- [x] **Given** I send it online, **When** accepted, **Then** a snackbar thanks me
- [x] **Given** I am offline, **When** I send it, **Then** it is queued in Drift and sent later
- [x] **Given** the daily limit, **When** reached, **Then** a friendly message explains it

## Technical Notes

- Random install ID stored in preferences.

## Dependencies

### Requires
- 003-lyrics-cache
- 003-report-function (backend)

### Enables
- None

## Edge Cases

| Scenario | Expected Behavior |
|----------|-------------------|
| Queued report for a song later removed | Dropped quietly |

## Out of Scope

- Viewing my reports
