---
id: 015-playlists
unit: 001-local-library-and-player-ui
intent: 002-local-library-and-player
status: draft
priority: must
created: 2026-10-24T19:22:00Z
assigned_bolt: 007-local-library-and-player-ui
implemented: false
---

# Story: 015-playlists

## User Story

**As a** listener
**I want** to make my own playlists
**So that** I can keep songs for a feast day or a service together

## Acceptance Criteria

- [ ] **Given** Playlists (S15), **When** shown, **Then** a "Create playlist" card, then user playlists (collage of up to 4 album covers, name, count)
- [ ] **Given** S16, **When** creating or renaming, **Then** the name is required and unique (case-insensitive, trimmed), the description optional; Save is disabled while invalid and a duplicate shows a message
- [ ] **Given** a playlist (S17), **When** opened, **Then** collage, name, count, total duration, Play and Shuffle
- [ ] **Given** S17, **When** a song is dragged, **Then** the order is saved
- [ ] **Given** S17, **When** a song is swiped away, **Then** it is removed with undo
- [ ] **Given** S17's menu, **When** Rename or Delete is chosen, **Then** S16 opens, or a confirmation dialog deletes the playlist
- [ ] **Given** a restart or rescan, **When** shown, **Then** playlists and their order are kept
- [ ] **Given** no user playlists, **When** shown, **Then** only the Create card and the auto playlists section (019) show

## Technical Notes

- Positions stored as integers and rewritten on reorder in one transaction.

## Dependencies

### Requires
- 002-library-database

### Enables
- 016-add-songs-picker
- 017-song-menu-and-add-to-playlist
- 019-play-history-and-auto-playlists

## Edge Cases

| Scenario | Expected Behavior |
|----------|-------------------|
| Name with only spaces | Invalid |
| Same song twice in a playlist | Not allowed: adding it again does nothing |

## Out of Scope

- Change cover
- Import/export playlists
