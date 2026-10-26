---
id: 012-lyrics-view-now-playing
unit: 001-lyrics-engine-and-display-ui
intent: 003-lyrics-engine-and-display
status: draft
priority: must
created: 2026-10-26T13:41:09Z
assigned_bolt: 015-lyrics-engine-and-display-ui
implemented: false
---

# Story: 012-lyrics-view-now-playing

## User Story

**As a** listener
**I want** to read synced lyrics while a song plays
**So that** I can sing along

## Acceptance Criteria

- [ ] **Given** a linked song with timings, **When** Now Playing shows lyrics, **Then** the current line is highlighted (`primaryText`), past lines dimmed (`faint`), chorus lines marked
- [ ] **Given** a line, **When** tapped, **Then** playback seeks to it
- [ ] **Given** a song without timings, **When** shown, **Then** plain lyrics show without highlight
- [ ] **Given** no linked song, **When** shown, **Then** a No lyrics state with Match lyrics shows
- [ ] **Given** the transliteration toggle, **When** on, **Then** each line shows its transliteration below
- [ ] **Given** 1.3× text in light and dark, **When** shown, **Then** nothing overflows

## Technical Notes

- C06 as a shared widget in `features/lyrics/presentation/`; Now Playing gains a lyrics/artwork switch.

## Dependencies

### Requires
- 008-sync-engine
- 011-track-song-linking

### Enables
- 013-lyrics-scroll-and-offset
- 014-song-detail

## Edge Cases

| Scenario | Expected Behavior |
|----------|-------------------|
| Track changes | Lyrics switch to the new song |

## Out of Scope

- Album-art colors (later)
