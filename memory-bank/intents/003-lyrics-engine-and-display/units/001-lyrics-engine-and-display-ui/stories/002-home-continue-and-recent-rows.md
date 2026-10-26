---
id: 002-home-continue-and-recent-rows
unit: 001-lyrics-engine-and-display-ui
intent: 003-lyrics-engine-and-display
status: draft
priority: must
created: 2026-10-26T13:41:09Z
assigned_bolt: 009-lyrics-engine-and-display-ui
implemented: false
---

# Story: 002-home-continue-and-recent-rows

## User Story

**As a** listener
**I want** to pick up where I left off and see what I played recently
**So that** I can get back to my music fast

## Acceptance Criteria

- [ ] **Given** a restored last queue, **When** Home shows, **Then** a Continue listening card shows the song, its position and a resume button that continues from that position
- [ ] **Given** play history, **When** Home shows, **Then** a Recently played row shows up to 10 latest songs; tapping one plays the row from it; See all opens the Recently played auto playlist
- [ ] **Given** user playlists, **When** Home shows, **Then** a Your playlists row shows them with covers; tapping one opens the playlist page
- [ ] **Given** a section with nothing to show, **When** Home shows, **Then** that section is hidden
- [ ] **Given** a song plays or a playlist changes, **When** Home is visible, **Then** the rows update without a restart

## Technical Notes

- Continue listening reads the player's restored queue (002 `restore()`); it hides while that song is already playing.
- Rows are horizontal lists with fixed item width; they scale at 1.3×.

## Dependencies

### Requires
- 001-home-header-and-quick-actions

### Enables
- None

## Edge Cases

| Scenario | Expected Behavior |
|----------|-------------------|
| Last song's file missing | Card hidden |
| Hidden songs in history | Left out |

## Out of Scope

- Detected songs in Recently played (007)
