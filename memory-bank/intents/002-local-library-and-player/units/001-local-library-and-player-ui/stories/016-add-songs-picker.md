---
id: 016-add-songs-picker
unit: 001-local-library-and-player-ui
intent: 002-local-library-and-player
status: draft
priority: must
created: 2026-10-24T20:15:00Z
assigned_bolt: 007-local-library-and-player-ui
implemented: false
---

# Story: 016-add-songs-picker

## User Story

**As a** listener
**I want** to add many songs to a playlist at once
**So that** building a playlist doesn't take forever

## Acceptance Criteria

- [ ] **Given** S17, **When** "Add songs" is tapped, **Then** S18 lists all visible tracks with checkboxes and a search field
- [ ] **Given** songs already in the playlist, **When** listed, **Then** they are marked and can't be added again
- [ ] **Given** selected songs, **When** shown, **Then** a sticky "Add N songs" button adds them to the end and returns to S17
- [ ] **Given** a search, **When** filtered, **Then** checked songs stay checked

## Technical Notes

- Reuses the Tracks filter logic from 005.

## Dependencies

### Requires
- 015-playlists

### Enables
- None

## Edge Cases

| Scenario | Expected Behavior |
|----------|-------------------|
| Nothing selected | Button disabled |
