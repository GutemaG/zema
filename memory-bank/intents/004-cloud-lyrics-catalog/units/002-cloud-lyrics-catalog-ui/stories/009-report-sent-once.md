---
id: 009-report-sent-once
unit: 002-cloud-lyrics-catalog-ui
intent: 004-cloud-lyrics-catalog
status: complete
priority: should
created: '2026-10-29T14:00:21Z'
assigned_bolt: 028-cloud-lyrics-catalog-ui
implemented: true
---

# Story: 009-report-sent-once

## User Story

**As a** moderator
**I want** each report stored once, even when the app sends it again
**So that** a slow network doesn't fill the queue with copies or use up a listener's daily reports

## Acceptance Criteria

- [x] **Given** a report the server already stored, **When** the app sends it again with the same report ID, **Then** no second row is stored and the call succeeds
- [x] **Given** a repeat, **When** counted for the daily limit, **Then** it doesn't count again
- [x] **Given** a report queued after a timeout, **When** it is sent from the queue, **Then** it keeps the report ID it was first sent with
- [x] **Given** pgTAP, **When** run, **Then** the repeat and the limit are tested

## Technical Notes

- Found on the emulator in bolt 027: a report that timed out had reached the server, and the queued copy was sent again.
- The report ID is a random UUID made by the app; it is unique per install hash in the database.

## Dependencies

### Requires
- 006-report-wrong-lyrics
- 003-report-function (backend)

### Enables
- None

## Edge Cases

| Scenario | Expected Behavior |
|----------|-------------------|
| Same report ID from another install | Stored as its own report |
| Queued before this change (no ID) | Given one when sent |

## Out of Scope

- Merging different reports about the same song
