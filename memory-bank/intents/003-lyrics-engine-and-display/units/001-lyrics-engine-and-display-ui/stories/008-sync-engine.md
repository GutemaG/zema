---
id: 008-sync-engine
unit: 001-lyrics-engine-and-display-ui
intent: 003-lyrics-engine-and-display
status: draft
priority: must
created: 2026-10-26T13:41:09Z
assigned_bolt: 012-lyrics-engine-and-display-ui
implemented: false
---

# Story: 008-sync-engine

## User Story

**As a** listener
**I want** the line being sung to be found exactly
**So that** the highlight matches the music

## Acceptance Criteria

- [ ] **Given** a position, offset and SyncTiming, **When** asked, **Then** the engine returns the current occurrence index and the next one
- [ ] **Given** a position before the first line, **When** asked, **Then** no line is current and the first is next
- [ ] **Given** a seek backwards or forwards, **When** asked, **Then** the result is correct without replaying from the start
- [ ] **Given** timing data, **When** tested at line boundaries ±0.3 s and with offsets ±0.5/±1 s, **Then** results are correct

## Technical Notes

- Binary search over occurrence start times; pure function, no timers.

## Dependencies

### Requires
- 007-lyrics-models-and-play-order

### Enables
- 012-lyrics-view-now-playing

## Edge Cases

| Scenario | Expected Behavior |
|----------|-------------------|
| After the last line | Last line stays current |
| Timing out of order | Rejected at load |

## Out of Scope

- Word-level timing
