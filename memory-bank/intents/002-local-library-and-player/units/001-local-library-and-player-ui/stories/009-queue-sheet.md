---
id: 009-queue-sheet
unit: 001-local-library-and-player-ui
intent: 002-local-library-and-player
status: draft
priority: must
created: 2026-10-24T19:22:00Z
assigned_bolt: 006-local-library-and-player-ui
implemented: false
---

# Story: 009-queue-sheet

## User Story

**As a** listener
**I want** to see and change what plays next
**So that** I can line up songs without building a playlist

## Acceptance Criteria

- [ ] **Given** Now Playing, **When** the queue button is tapped, **Then** C02 opens with the current track highlighted and the upcoming tracks below
- [ ] **Given** C02, **When** a track is dragged, **Then** the play order changes
- [ ] **Given** C02, **When** a track is swiped away, **Then** it leaves the queue with an undo snackbar; the current track cannot be removed
- [ ] **Given** C02, **When** "Clear queue" is tapped, **Then** everything after the current track is removed
- [ ] **Given** C02, **When** a track is tapped, **Then** it plays
- [ ] **Given** shuffle is on, **When** C02 is open, **Then** it shows the shuffled order

## Technical Notes

- Reorder uses `ReorderableListView`; logic in the pure-Dart queue class from 006.

## Dependencies

### Requires
- 006-playback-engine
- 007-mini-player-and-now-playing

### Enables
- 017-song-menu-and-add-to-playlist

## Edge Cases

| Scenario | Expected Behavior |
|----------|-------------------|
| Queue of 1,000 tracks | Opens quickly and scrolls to the current track |

## Out of Scope

- Saving the queue as a playlist
