---
id: 003-report-function
unit: 001-cloud-lyrics-catalog-backend
intent: 004-cloud-lyrics-catalog
status: draft
priority: should
created: 2026-10-29T05:59:04Z
assigned_bolt: 019-cloud-lyrics-catalog-backend
implemented: false
---

# Story: 003-report-function

## User Story

**As a** listener
**I want** to report wrong lyrics without signing in
**So that** mistakes get fixed

## Acceptance Criteria

- [ ] **Given** a song, optional recording, reason, note and install ID, **When** `submit_report` is called anonymously, **Then** a report row is stored
- [ ] **Given** 5 reports from one install ID today, **When** a 6th is submitted, **Then** it is refused with a recognisable error code
- [ ] **Given** a reason outside the allowed list, a note over 500 characters, or an unknown or unapproved song, **When** submitted, **Then** it is refused
- [ ] **Given** pgTAP, **When** run, **Then** the rate limit and validation are tested

## Technical Notes

- SECURITY DEFINER function owned by a role that can insert reports; the table itself stays closed to `anon`. Install ID stored hashed.

## Dependencies

### Requires
- 002-row-level-security

### Enables
- 006-report-wrong-lyrics (ui)

## Edge Cases

| Scenario | Expected Behavior |
|----------|-------------------|
| Clock at midnight | Limit counts the last 24 h, not the calendar day |

## Out of Scope

- Moderator tools
