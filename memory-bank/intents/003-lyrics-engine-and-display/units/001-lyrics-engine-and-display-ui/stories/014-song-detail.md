---
id: 014-song-detail
unit: 001-lyrics-engine-and-display-ui
intent: 003-lyrics-engine-and-display
status: complete
priority: must
created: 2026-10-26T13:41:09Z
assigned_bolt: 016-lyrics-engine-and-display-ui
implemented: true
---

# Story: 014-song-detail

## User Story

**As a** listener
**I want** a page about one song with its full lyrics
**So that** I can read the lyrics without playing

## Acceptance Criteria

- [x] **Given** the song menu's View lyrics or a lyric search result, **When** chosen, **Then** Song detail opens with title, transliteration, artist, album and Play, favorite, add to playlist
- [x] **Given** the Lyrics tab, **When** shown, **Then** sections show with chorus blocks and ↻ repeat markers and A−/A+ font size
- [x] **Given** the Info tab, **When** shown, **Then** album, artist and source (bundled sample) show
- [x] **Given** a malformed link, **When** opened, **Then** C07 not found

## Technical Notes

- Route `/song/:id`.

## Dependencies

### Requires
- 012-lyrics-view-now-playing

### Enables
- None

## Edge Cases

| Scenario | Expected Behavior |
|----------|-------------------|
| Song with no linked local track | Play hidden |

## Out of Scope

- Recordings tab, report wrong lyrics (P2)
