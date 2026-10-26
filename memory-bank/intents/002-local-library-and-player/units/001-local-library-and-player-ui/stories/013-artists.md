---
id: 013-artists
unit: 001-local-library-and-player-ui
intent: 002-local-library-and-player
status: complete
priority: should
created: 2026-10-24T19:22:00Z
assigned_bolt: 006-local-library-and-player-ui
implemented: true
---

# Story: 013-artists

## User Story

**As a** listener
**I want** to browse my music by singer
**So that** I can play everything by one mezmur singer

## Acceptance Criteria

- [ ] **Given** Artists, **When** shown, **Then** a list with an avatar (one of their album covers, or initials) and a song count
- [ ] **Given** an artist, **When** opened (S13a), **Then** their albums and songs, with Play and Shuffle
- [ ] **Given** "Unknown artist", **When** shown, **Then** tracks without artist metadata group there

## Technical Notes

- Split multiple artists ("A & B", "A, B")? Not in this intent: the artist string is used as is.

## Dependencies

### Requires
- 004-library-scan-and-sync

### Enables
- 017-song-menu-and-add-to-playlist

## Out of Scope

- Artist photos from the internet
