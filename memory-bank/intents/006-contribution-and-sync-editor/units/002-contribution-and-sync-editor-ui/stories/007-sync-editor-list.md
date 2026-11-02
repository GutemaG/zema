---
id: 007-sync-editor-list
unit: 002-contribution-and-sync-editor-ui
intent: 006-contribution-and-sync-editor
status: complete
priority: must
created: '2026-11-02T07:00:52Z'
assigned_bolt: 046-contribution-and-sync-editor-ui
implemented: true
---

# Story: 007-sync-editor-list

## User Story

**As a** contributor
**I want** to tap along with the recording to time each line
**So that** the lyrics highlight in time for everyone

## Acceptance Criteria

- [ ] **Given** S21 with local or Telegram audio, **When** opened, **Then** the List view shows the playback bar (play/pause, position/duration, −5 s, 0.75×/1×), every line occurrence in play order with its time or —, the current line highlighted, Undo last tap and a large Tap — next line; no step or line counters
- [ ] **Given** playing, **When** Tap — next line, **Then** the current position (within 50 ms) is recorded for the highlighted line and the next one highlights
- [ ] **Given** a timed line, **When** selected, **Then** holding nudge moves it ±0.1 s without passing its neighbours; Redo from here clears it and later lines and plays from 3 s before
- [ ] **Given** Undo last tap, **When** pressed, **Then** the last time is cleared and that line highlights again
- [ ] **Given** chorus repeats, **When** shown, **Then** each occurrence is its own row and time
- [ ] **Given** Skip — submit text only, **When** pressed, **Then** S22 opens with no timings
- [ ] **Given** any tap, **When** made, **Then** the draft is saved; the main player is paused while S21 is open

## Technical Notes

- Separate just_audio instance. Design `07a-sync-list.png` without the counters; waveform may be a plain bar if it costs too much.

## Dependencies

### Requires
- 005-link-recording

### Enables
- 008-sync-editor-focus-and-preview

## Edge Cases

| Scenario | Expected Behavior |
|----------|-------------------|
| Tap after the last line | Ignored |
| App backgrounded | Playback pauses; times kept |

## Out of Scope

- YouTube sync
