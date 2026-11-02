---
id: 010-duplicate-check-and-entry-points
unit: 002-contribution-and-sync-editor-ui
intent: 006-contribution-and-sync-editor
status: planned
priority: must
created: '2026-11-02T07:00:52Z'
assigned_bolt: 049-contribution-and-sync-editor-ui
implemented: false
---

# Story: 010-duplicate-check-and-entry-points

## User Story

**As a** contributor
**I want** to be warned about similar songs and to start contributing from where I am
**So that** I don't add duplicates and contributing is easy to find

## Acceptance Criteria

- [ ] **Given** S19's title, **When** typed (after a short pause), **Then** catalog matches show as A similar song exists; choosing one switches to adding a recording or suggesting a correction; it can be ignored
- [ ] **Given** search with no results, **When** Add this song's lyrics, **Then** S19 opens with the title
- [ ] **Given** a track with no lyrics, **When** Add lyrics, **Then** S19 opens with title, artist and the track preselected
- [ ] **Given** Song detail, **When** Link a recording / Sync this recording, **Then** S20 for that song / S21 for the playing file's recording without timings
- [ ] **Given** a guest, **When** any of these, **Then** C09 first

## Technical Notes

- Uses 004's catalog search.

## Dependencies

### Requires
- 009-review-and-submit

### Enables
- 011-corrections

## Edge Cases

| Scenario | Expected Behavior |
|----------|-------------------|
| Offline duplicate check | Skipped quietly |
