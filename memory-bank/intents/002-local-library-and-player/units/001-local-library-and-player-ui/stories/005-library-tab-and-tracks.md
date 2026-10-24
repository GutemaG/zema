---
id: 005-library-tab-and-tracks
unit: 001-local-library-and-player-ui
intent: 002-local-library-and-player
status: complete
priority: must
created: 2026-10-24T19:22:00Z
assigned_bolt: 005-local-library-and-player-ui
implemented: true
---

# Story: 005-library-tab-and-tracks

## User Story

**As a** listener
**I want** to see all my songs, find one fast and play it
**So that** I get to the song I want in a few seconds

## Acceptance Criteria

- [ ] **Given** the Library tab, **When** opened, **Then** top tabs Tracks, Folders, Albums, Artists, Favorites, Playlists show, Tracks first; the selected tab is kept when switching bottom tabs
- [ ] **Given** Tracks, **When** shown, **Then** it shows the track count and rows with art (or placeholder), title, artist · duration
- [ ] **Given** the search field, **When** typing, **Then** rows filter by title, artist and album (case-insensitive) within 100 ms on 1,000 tracks
- [ ] **Given** the sort menu, **When** a field (title, artist, album, date added, duration) and direction are chosen, **Then** the list re-sorts and the choice survives a restart
- [ ] **Given** sorting by title, artist or album, **When** the alphabet bar is dragged, **Then** the list jumps to that initial (Latin A–Z and Ethiopic initials present in the list)
- [ ] **Given** a row, **When** tapped, **Then** the filtered, sorted list plays from that track
- [ ] **Given** Play or Shuffle, **When** tapped, **Then** the visible list plays in order or shuffled
- [ ] **Given** an empty library or no search results, **When** shown, **Then** C07 empty with a suitable message
- [ ] **Given** 1,000 tracks, **When** scrolled in profile mode, **Then** no frames over 16 ms on the emulator and art loads lazily
- [ ] **Given** 1.3× text, light and dark, both palettes, **When** shown, **Then** nothing overflows and contrast rules hold

## Technical Notes

- The other top tabs show C07 "Coming soon" until their stories land.
- Shared `TrackRow` and `TrackArt` widgets in `lib/shared/widgets/` (reused by every list).
- Ethiopic initials: the first fidel's base consonant family (e.g. ሀ ሁ ሂ → ሀ).

## Dependencies

### Requires
- 004-library-scan-and-sync

### Enables
- 006-playback-engine
- 018-track-multi-select

## Edge Cases

| Scenario | Expected Behavior |
|----------|-------------------|
| Title starts with a digit or symbol | Grouped under # |
| Search with Ethiopic text | Matches substrings; variant normalization comes in 003 |

## Out of Scope

- Lyrics status icon on rows (003)
- Multi-select (018)
