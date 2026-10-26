---
id: 005-search-screen
unit: 001-lyrics-engine-and-display-ui
intent: 003-lyrics-engine-and-display
status: complete
priority: must
created: 2026-10-26T13:41:09Z
assigned_bolt: 011-lyrics-engine-and-display-ui
implemented: true
---

# Story: 005-search-screen

## User Story

**As a** listener
**I want** one search field for my whole library
**So that** I can find a song, artist or album quickly

## Acceptance Criteria

- [x] **Given** the Search tab, **When** I type, **Then** results update while typing, grouped Songs, Artists, Albums, using normalization and transliteration
- [x] **Given** scope chips All, Songs, Artists, Albums, **When** one is chosen, **Then** only that group shows
- [x] **Given** a song result, **When** tapped, **Then** it plays (queue = song results); its menu is the song menu; artist and album results open their pages
- [x] **Given** no results, **When** shown, **Then** the C07 no-results state shows
- [x] **Given** 1,000 tracks, **When** typing, **Then** each keystroke's results take < 100 ms (measured in a test)

## Technical Notes

- Replaces `search_screen.dart` "Coming soon"; an index of normalized fields is built once per library change.
- Lyrics chip added in story 015.

## Dependencies

### Requires
- 003-ethiopic-normalization
- 004-transliteration-matching

### Enables
- 006-recent-searches
- 015-lyric-text-search

## Edge Cases

| Scenario | Expected Behavior |
|----------|-------------------|
| Hidden songs | Not in results |
| Keyboard open | Results scroll under the field; dismiss on drag |

## Out of Scope

- Cloud results (004), popular songs
