---
id: 009-lrc-import
unit: 001-lyrics-engine-and-display-ui
intent: 003-lyrics-engine-and-display
status: complete
priority: must
created: 2026-10-26T13:41:09Z
assigned_bolt: 013-lyrics-engine-and-display-ui
implemented: true
---

# Story: 009-lrc-import

## User Story

**As a** developer
**I want** to write sample timings as LRC
**So that** timings are easy to make and users' LRC files can be read later

## Acceptance Criteria

- [x] **Given** LRC with `[mm:ss.xx]` tags, **When** imported, **Then** a Song, Recording and SyncTiming result
- [x] **Given** a line with several time tags, **When** imported, **Then** one line with several occurrences results
- [x] **Given** consecutive lines that repeat as a block, **When** imported, **Then** they become one chorus section in the play order
- [x] **Given** `[offset:]`, `[ti:]`, `[ar:]`, `[al:]` tags, **When** imported, **Then** they set the offset and song metadata
- [x] **Given** malformed lines, **When** imported, **Then** they are skipped and listed in the result; Ethiopic text is kept exactly

## Technical Notes

- Pure Dart in `zema_core`.

## Dependencies

### Requires
- 007-lyrics-models-and-play-order

### Enables
- 010-bundled-lyrics-repository

## Edge Cases

| Scenario | Expected Behavior |
|----------|-------------------|
| Empty file | Error result, no song |

## Out of Scope

- LRC export (006)
