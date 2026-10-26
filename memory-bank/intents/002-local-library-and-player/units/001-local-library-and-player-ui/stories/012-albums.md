---
id: 012-albums
unit: 001-local-library-and-player-ui
intent: 002-local-library-and-player
status: complete
priority: must
created: 2026-10-24T19:22:00Z
assigned_bolt: 006-local-library-and-player-ui
implemented: true
---

# Story: 012-albums

## User Story

**As a** listener
**I want** to browse my music by album
**So that** I can play an album in order

## Acceptance Criteria

- [ ] **Given** Albums, **When** shown, **Then** a grid of covers with album and artist, sortable by name, artist or year
- [ ] **Given** an album, **When** opened (S12a), **Then** cover, name, artist, year, track count, total duration and a numbered track list (by track number, then title), with Play and Shuffle
- [ ] **Given** a missing cover, **When** shown, **Then** a placeholder from the theme
- [ ] **Given** "Unknown album", **When** shown, **Then** tracks without album metadata group there

## Technical Notes

- Grid column count adapts to width (2 on phones).

## Dependencies

### Requires
- 004-library-scan-and-sync

### Enables
- 017-song-menu-and-add-to-playlist

## Edge Cases

| Scenario | Expected Behavior |
|----------|-------------------|
| Album with tracks from several artists | Artist shows the album artist or "Various artists" |
