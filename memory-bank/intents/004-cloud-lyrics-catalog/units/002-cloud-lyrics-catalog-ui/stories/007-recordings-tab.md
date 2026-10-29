---
id: 007-recordings-tab
unit: 002-cloud-lyrics-catalog-ui
intent: 004-cloud-lyrics-catalog
status: complete
priority: should
created: '2026-10-29T05:59:04Z'
assigned_bolt: 027-cloud-lyrics-catalog-ui
implemented: true
---

# Story: 007-recordings-tab

## User Story

**As a** listener
**I want** to see a song's recordings
**So that** I know which versions have synced lyrics

## Acceptance Criteria

- [x] **Given** Song detail, **When** I open Recordings, **Then** each recording shows artist, source, duration and Synced or Text only
- [x] **Given** the recording used by the lyrics view, **When** listed, **Then** it is marked
- [x] **Given** 1.3× text in light and dark, **When** shown, **Then** nothing overflows

## Technical Notes

- None beyond the unit brief.

## Dependencies

### Requires
- 003-lyrics-cache

### Enables
- None

## Edge Cases

| Scenario | Expected Behavior |
|----------|-------------------|
| No recordings | Empty state text |

## Out of Scope

- Choosing a recording
