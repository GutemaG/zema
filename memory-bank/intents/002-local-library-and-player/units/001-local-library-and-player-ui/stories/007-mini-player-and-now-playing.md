---
id: 007-mini-player-and-now-playing
unit: 001-local-library-and-player-ui
intent: 002-local-library-and-player
status: draft
priority: must
created: 2026-10-24T19:22:00Z
assigned_bolt: 005-local-library-and-player-ui
implemented: false
---

# Story: 007-mini-player-and-now-playing

## User Story

**As a** listener
**I want** to see and control what is playing from anywhere in the app
**So that** I never have to hunt for the controls

## Acceptance Criteria

- [ ] **Given** something is loaded, **When** on any tab, **Then** the mini player sits above the bottom nav with art, title, artist, play/pause, next and a progress line
- [ ] **Given** the mini player, **When** tapped, **Then** Now Playing (S08) opens; swipe down or back closes it
- [ ] **Given** S08, **When** shown, **Then** it has art, title, artist, a seek bar with elapsed and remaining time, shuffle, previous, play/pause, next, repeat, and buttons for queue, sleep timer, add to playlist and favorite
- [ ] **Given** S08's lyrics area, **When** shown, **Then** it says "No lyrics yet"
- [ ] **Given** the seek bar, **When** dragged, **Then** the time label follows and audio seeks on release
- [ ] **Given** light and dark mode and both palettes, **When** shown, **Then** colors come from `ZemaColors` and thin progress uses `accent` in light mode
- [ ] **Given** TalkBack, **When** focused, **Then** each control has a label and the seek bar announces position and duration
- [ ] **Given** nothing loaded, **When** on any tab, **Then** no mini player shows

## Technical Notes

- Buttons whose stories come later (queue, sleep timer, add to playlist, favorite) are wired as they land; until then they are hidden, not disabled.
- Mini player lives in `AppShell` so it shows on all four tabs.

## Dependencies

### Requires
- 006-playback-engine

### Enables
- 009-queue-sheet
- 010-sleep-timer
- 017-song-menu-and-add-to-playlist

## Edge Cases

| Scenario | Expected Behavior |
|----------|-------------------|
| Very long Ethiopic title | Ellipsized on the mini player; marquee not required |
| 1.3× text on the mini player | No overflow |

## Out of Scope

- Lyrics (003)
- Album-art colors (003)
- View-only mode for detected songs (007)
