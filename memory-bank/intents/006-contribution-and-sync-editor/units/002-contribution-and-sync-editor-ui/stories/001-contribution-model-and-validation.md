---
id: 001-contribution-model-and-validation
unit: 002-contribution-and-sync-editor-ui
intent: 006-contribution-and-sync-editor
status: complete
priority: must
created: '2026-11-02T07:00:52Z'
assigned_bolt: 042-contribution-and-sync-editor-ui
implemented: true
---

# Story: 001-contribution-model-and-validation

## User Story

**As a** developer
**I want** one model and rule set for contributions in `zema_core`
**So that** the app and server agree on what is valid

## Acceptance Criteria

- [x] **Given** a draft (song, blocks, play order, optional recording and timings), **When** validated, **Then** errors name the field: title (1–200 trimmed), ≥1 block each with a non-empty line, ≤300 lines, play order non-empty and only existing blocks, one timing per line occurrence, non-negative and strictly increasing, within a known duration
- [x] **Given** pasted text, **When** `splitPastedLyrics` runs, **Then** blank lines split blocks, a block equal to an earlier one becomes a repeat in the play order and that block is marked Chorus
- [x] **Given** a YouTube link (watch, youtu.be, shorts, music.youtube, with extra parameters), **When** parsed, **Then** the 11-character video ID comes back, or null
- [x] **Given** a draft, **When** turned into a payload, **Then** it is a song document in 004's JSON format (with `recordings` and `timings` when present) and round-trips
- [x] **Given** tests, **When** run, **Then** rules, split, parser and round-trip are covered

## Technical Notes

- Line occurrences come from the existing `play_order.dart`. Error codes match the backend's (backend 001).

## Dependencies

### Requires
- None

### Enables
- 002-contribution-repository
- 004-add-lyrics-editor

## Edge Cases

| Scenario | Expected Behavior |
|----------|-------------------|
| Paste with Windows line endings and trailing spaces | Same split |
| Chorus pasted three times | One Chorus block, three play-order entries |

## Out of Scope

- UI
