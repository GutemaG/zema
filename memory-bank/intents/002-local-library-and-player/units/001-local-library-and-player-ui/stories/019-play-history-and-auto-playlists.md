---
id: 019-play-history-and-auto-playlists
unit: 001-local-library-and-player-ui
intent: 002-local-library-and-player
status: complete
priority: must
created: 2026-10-24T19:22:00Z
assigned_bolt: 008-local-library-and-player-ui
implemented: true
---

# Story: 019-play-history-and-auto-playlists

## User Story

**As a** listener
**I want** the app to remember what I play
**So that** I can get back to recent and favourite songs without searching

## Acceptance Criteria

- [ ] **Given** a track plays for 30 s (or to the end, if shorter), **When** that point is reached, **Then** one play event is stored; seeking or replaying within the same play doesn't double-count
- [ ] **Given** play events, **When** Playlists shows, **Then** read-only auto playlists Recently added (last 30 days), Most played (top 50) and Recently played (last 50, newest first) appear
- [ ] **Given** an auto playlist, **When** opened, **Then** it shows the tracks with Play and Shuffle but no reorder, remove or rename
- [ ] **Given** a restart or rescan, **When** shown, **Then** counts and history are kept
- [ ] **Given** events older than one year, **When** the app starts, **Then** they are pruned
- [ ] **Given** tests, **When** run, **Then** play counting is unit-tested with a fake clock and the auto playlist queries with an in-memory database

## Technical Notes

- Counting lives with the player; queries in the library DAO.

## Dependencies

### Requires
- 006-playback-engine
- 015-playlists

### Enables
- None

## Edge Cases

| Scenario | Expected Behavior |
|----------|-------------------|
| Hidden or missing tracks | Left out of auto playlists |

## Out of Scope

- Home screen recent rows
