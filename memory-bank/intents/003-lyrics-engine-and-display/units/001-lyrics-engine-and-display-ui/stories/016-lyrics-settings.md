---
id: 016-lyrics-settings
unit: 001-lyrics-engine-and-display-ui
intent: 003-lyrics-engine-and-display
status: complete
priority: must
created: 2026-10-26T13:41:09.000Z
assigned_bolt: 017-lyrics-engine-and-display-ui
implemented: true
---

# Story: 016-lyrics-settings

## User Story

**As a** listener
**I want** to set lyrics font size, transliteration and default offset once
**So that** lyrics look right everywhere

## Acceptance Criteria

- [x] **Given** Settings, **When** shown, **Then** a Lyrics section shows font size, show transliteration and default sync offset
- [x] **Given** a change, **When** made, **Then** it applies to the lyrics view and Song detail at once and persists
- [x] **Given** a recording with its own offset, **When** shown, **Then** its offset wins over the default

## Technical Notes

- Extends `AppSettings` / `SettingsController`.

## Dependencies

### Requires
- 013-lyrics-scroll-and-offset

### Enables
- None

## Edge Cases

| Scenario | Expected Behavior |
|----------|-------------------|
| — | — |

## Out of Scope

- Floating lyrics settings (007)
