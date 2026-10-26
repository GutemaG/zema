---
id: 018-track-multi-select
unit: 001-local-library-and-player-ui
intent: 002-local-library-and-player
status: complete
priority: must
created: 2026-10-24T19:22:00Z
assigned_bolt: 008-local-library-and-player-ui
implemented: true
---

# Story: 018-track-multi-select

## User Story

**As a** listener
**I want** to act on many songs at once
**So that** organizing a large library is quick

## Acceptance Criteria

- [ ] **Given** Tracks, **When** a row is long-pressed, **Then** selection mode starts with that row selected and a bar showing the count
- [ ] **Given** selection mode, **When** rows are tapped, **Then** they toggle; "Select all" selects the visible list
- [ ] **Given** a selection, **When** add to playlist, add to queue, favorite or hide is chosen, **Then** it applies to all selected songs and selection mode ends with a snackbar (undo for hide)
- [ ] **Given** selection mode, **When** back is pressed, **Then** selection ends without changes

## Technical Notes

- Selection state in a local Notifier; actions reuse the song-menu operations.

## Dependencies

### Requires
- 005-library-tab-and-tracks
- 017-song-menu-and-add-to-playlist

### Enables
- None

## Out of Scope

- Multi-select in other tabs
