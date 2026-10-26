---
id: 015-lyric-text-search
unit: 001-lyrics-engine-and-display-ui
intent: 003-lyrics-engine-and-display
status: draft
priority: must
created: 2026-10-26T13:41:09Z
assigned_bolt: 016-lyrics-engine-and-display-ui
implemented: false
---

# Story: 015-lyric-text-search

## User Story

**As a** listener
**I want** to find a song by a line I remember
**So that** I can find it without the title

## Acceptance Criteria

- [ ] **Given** a query, **When** searching, **Then** a Lyrics group lists songs whose lyric lines match, showing the matching line
- [ ] **Given** the Lyrics chip, **When** chosen, **Then** only lyric matches show
- [ ] **Given** a lyric result, **When** tapped, **Then** Song detail opens
- [ ] **Given** search timing, **When** measured, **Then** < 100 ms per keystroke still holds

## Technical Notes

- Lines indexed with the same normalization.

## Dependencies

### Requires
- 005-search-screen
- 010-bundled-lyrics-repository

### Enables
- None

## Edge Cases

| Scenario | Expected Behavior |
|----------|-------------------|
| Same line in several songs | Each song once |

## Out of Scope

- Cloud lyric search (004)
