---
id: 011-track-song-linking
unit: 001-lyrics-engine-and-display-ui
intent: 003-lyrics-engine-and-display
status: draft
priority: must
created: 2026-10-26T13:41:09Z
assigned_bolt: 014-lyrics-engine-and-display-ui
implemented: false
---

# Story: 011-track-song-linking

## User Story

**As a** listener
**I want** my songs linked to their lyrics automatically, or by hand when needed
**So that** lyrics show for the songs I play

## Acceptance Criteria

- [ ] **Given** a track whose normalized title and artist match a song above the threshold, **When** the library or lyrics change, **Then** it is linked automatically
- [ ] **Given** the song menu, **When** I choose Match lyrics, **Then** a search picker of songs opens and my choice links the track; Unlink removes it
- [ ] **Given** a manual link, **When** a rescan or automatic matching runs, **Then** the manual link wins
- [ ] **Given** Drift, **When** upgraded, **Then** schema v2 adds the link table and a v1 → v2 migration test passes

## Technical Notes

- Link table keyed by Zema track ID; source automatic/manual.

## Dependencies

### Requires
- 004-transliteration-matching
- 010-bundled-lyrics-repository

### Enables
- 012-lyrics-view-now-playing

## Edge Cases

| Scenario | Expected Behavior |
|----------|-------------------|
| Two songs match equally | No automatic link |
| Linked song removed from assets | Link ignored |

## Out of Scope

- Recordings for other sources (007)
