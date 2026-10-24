---
id: 010-sleep-timer
unit: 001-local-library-and-player-ui
intent: 002-local-library-and-player
status: draft
priority: must
created: 2026-10-24T20:15:00Z
assigned_bolt: 006-local-library-and-player-ui
implemented: false
---

# Story: 010-sleep-timer

## User Story

**As a** listener
**I want** music to stop on its own after a while
**So that** I can fall asleep listening to mezmur

## Acceptance Criteria

- [ ] **Given** Now Playing, **When** the sleep timer button is tapped, **Then** C05 offers 15, 30, 45, 60 min, end of current song and custom (1–180 min)
- [ ] **Given** a timer is set, **When** C05 or S08 shows, **Then** remaining time is visible and the timer can be cancelled
- [ ] **Given** the timer ends, **When** it fires, **Then** volume fades out over 5 s and playback pauses; volume is restored for the next play
- [ ] **Given** "end of current song", **When** the track ends, **Then** playback stops
- [ ] **Given** the app is in the background or the screen is off, **When** the timer ends, **Then** it still stops playback
- [ ] **Given** tests, **When** run, **Then** timer logic is tested with a fake clock

## Technical Notes

- Timer lives in the audio handler so it survives the UI being closed.
- Default preselection comes from the Playback setting (021).

## Dependencies

### Requires
- 006-playback-engine
- 007-mini-player-and-now-playing

### Enables
- 021-playback-settings

## Edge Cases

| Scenario | Expected Behavior |
|----------|-------------------|
| Pause during the timer | Timer keeps counting |
| Custom value out of range | Save disabled with a message |
