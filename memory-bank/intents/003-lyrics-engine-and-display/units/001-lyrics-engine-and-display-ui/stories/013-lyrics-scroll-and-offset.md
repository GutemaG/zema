---
id: 013-lyrics-scroll-and-offset
unit: 001-lyrics-engine-and-display-ui
intent: 003-lyrics-engine-and-display
status: draft
priority: must
created: 2026-10-26T13:41:09Z
assigned_bolt: 015-lyrics-engine-and-display-ui
implemented: false
---

# Story: 013-lyrics-scroll-and-offset

## User Story

**As a** listener
**I want** the lyrics to follow the song and to fix timing that is a bit off
**So that** I don't lose my place

## Acceptance Criteria

- [ ] **Given** playback, **When** the line changes, **Then** the view scrolls to keep the current line in view
- [ ] **Given** I scroll manually, **When** 3 s pass without touching, **Then** auto-scroll resumes
- [ ] **Given** the overflow menu, **When** I adjust the sync offset in 0.5 s steps, **Then** the highlight moves at once and the offset is saved for that recording
- [ ] **Given** a font size change (A−/A+), **When** applied, **Then** the view keeps the current line in view

## Technical Notes

- Offsets keyed by recording ID in `SettingsRepository`.

## Dependencies

### Requires
- 012-lyrics-view-now-playing

### Enables
- None

## Edge Cases

| Scenario | Expected Behavior |
|----------|-------------------|
| Offset beyond ±10 s | Clamped |

## Out of Scope

- Per-line timing edits (006)
