---
id: 007-lyrics-models-and-play-order
unit: 001-lyrics-engine-and-display-ui
intent: 003-lyrics-engine-and-display
status: draft
priority: must
created: 2026-10-26T13:41:09Z
assigned_bolt: 012-lyrics-engine-and-display-ui
implemented: false
---

# Story: 007-lyrics-models-and-play-order

## User Story

**As a** developer
**I want** immutable lyrics models with a play order
**So that** chorus text is written once and timings can address every sung line

## Acceptance Criteria

- [ ] **Given** `zema_core`, **When** used, **Then** Song, LyricSection (verse/chorus/bridge, lines), PlayOrder, Recording and SyncTiming exist as immutable models with JSON round trip
- [ ] **Given** a play order with a repeated chorus, **When** expanded, **Then** a flat list of line occurrences results, each with section, line and occurrence index
- [ ] **Given** a bridge, an empty section or a play order referencing a missing section, **When** expanded, **Then** empty sections add nothing and missing ones are reported
- [ ] **Given** tests, **When** run, **Then** expansion and JSON are unit-tested

## Technical Notes

- `packages/zema_core/lib/src/lyrics/`.

## Dependencies

### Requires
- None

### Enables
- 008-sync-engine
- 009-lrc-import

## Edge Cases

| Scenario | Expected Behavior |
|----------|-------------------|
| No play order | Sections in written order |

## Out of Scope

- Contribution status fields (006)
