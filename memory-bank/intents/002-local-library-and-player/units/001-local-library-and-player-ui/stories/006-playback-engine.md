---
id: 006-playback-engine
unit: 001-local-library-and-player-ui
intent: 002-local-library-and-player
status: draft
priority: must
created: 2026-10-24T19:22:00Z
assigned_bolt: 005-local-library-and-player-ui
implemented: false
---

# Story: 006-playback-engine

## User Story

**As a** listener
**I want** to play my songs reliably, with shuffle and repeat
**So that** music plays the way I expect

## Acceptance Criteria

- [ ] **Given** a list and a start index, **When** played, **Then** audio starts in under 1 s and the queue holds the list
- [ ] **Given** playing, **When** pause, play, seek, next or previous are used, **Then** they act immediately; previous restarts the track if more than 3 s in
- [ ] **Given** shuffle on, **When** turned on, **Then** the current track stays and the rest are shuffled; off restores the original order after the current track
- [ ] **Given** repeat off / all / one, **When** the queue ends or a track ends, **Then** it stops / starts over / repeats the track
- [ ] **Given** an unplayable file, **When** reached, **Then** it is skipped with a snackbar and the queue continues
- [ ] **Given** the app is closed and reopened, **When** it starts, **Then** the last queue, track and position are restored, paused
- [ ] **Given** player state, **When** read anywhere, **Then** it comes from Riverpod providers (`playerStateProvider`, `positionProvider`, `currentTrackProvider`) that later intents can use
- [ ] **Given** tests, **When** run, **Then** queue, shuffle, repeat and previous logic are unit-tested against a fake audio handler

## Technical Notes

- `just_audio` behind an `audio_service` `AudioHandler`; queue logic in a pure-Dart class so it is testable without plugins.
- Play by content URI (`content://media/...`).
- Last queue (track IDs, index, position) saved to shared_preferences on pause and every 10 s while playing.

## Dependencies

### Requires
- 005-library-tab-and-tracks

### Enables
- 007-mini-player-and-now-playing
- 008-media-notification
- 009-queue-sheet
- 010-sleep-timer
- 019-play-history-and-auto-playlists

## Edge Cases

| Scenario | Expected Behavior |
|----------|-------------------|
| A restored track was deleted | It is dropped from the restored queue |
| Queue of one with repeat all | Restarts the same track |

## Out of Scope

- Crossfade
- Equalizer
