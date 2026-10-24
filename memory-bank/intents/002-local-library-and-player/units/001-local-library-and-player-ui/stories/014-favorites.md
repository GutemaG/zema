---
id: 014-favorites
unit: 001-local-library-and-player-ui
intent: 002-local-library-and-player
status: draft
priority: must
created: 2026-10-24T19:22:00Z
assigned_bolt: 007-local-library-and-player-ui
implemented: false
---

# Story: 014-favorites

## User Story

**As a** listener
**I want** to mark songs I love and find them in one place
**So that** my favourite mezmur are one tap away

## Acceptance Criteria

- [ ] **Given** a track, **When** favorited from Now Playing (and later the song menu and multi-select), **Then** the heart state updates everywhere immediately
- [ ] **Given** Favorites, **When** shown, **Then** favorited songs, newest first, with search, Play and Shuffle
- [ ] **Given** Favorites, **When** a song is removed, **Then** an undo snackbar restores it at the same place
- [ ] **Given** a restart or rescan, **When** Favorites shows, **Then** all favorites are kept (missing files hidden, not removed)
- [ ] **Given** no favorites, **When** shown, **Then** C07 empty explaining how to add one

## Technical Notes

- `favoritesProvider` stream from Drift; `isFavoriteProvider(trackId)` family for hearts.

## Dependencies

### Requires
- 002-library-database
- 007-mini-player-and-now-playing

### Enables
- 017-song-menu-and-add-to-playlist
- 018-track-multi-select

## Out of Scope

- Cloud songs in favorites (004+)
