---
id: 017-song-menu-and-add-to-playlist
unit: 001-local-library-and-player-ui
intent: 002-local-library-and-player
status: draft
priority: must
created: 2026-10-24T20:15:00Z
assigned_bolt: 007-local-library-and-player-ui
implemented: false
---

# Story: 017-song-menu-and-add-to-playlist

## User Story

**As a** listener
**I want** quick actions on any song
**So that** I can queue, save or share a song from wherever I see it

## Acceptance Criteria

- [ ] **Given** any track row or Now Playing, **When** the menu opens (C03), **Then** it offers play next, add to queue, add to playlist, favorite/unfavorite, go to album, go to artist, hide and share
- [ ] **Given** "Play next" or "Add to queue", **When** chosen, **Then** the track goes after the current one or to the end, with a snackbar
- [ ] **Given** "Add to playlist", **When** chosen, **Then** C04 shows "New playlist" and existing playlists with checkmarks; tapping a playlist adds or removes the song immediately
- [ ] **Given** "New playlist" in C04, **When** S16 is saved, **Then** the playlist is created and the song added
- [ ] **Given** "Hide", **When** chosen, **Then** the song disappears everywhere with an undo snackbar
- [ ] **Given** "Share", **When** chosen, **Then** the Android share sheet opens with the audio file
- [ ] **Given** "Go to album" / "Go to artist", **When** chosen, **Then** S12a / S13a opens
- [ ] **Given** view lyrics and edit info, **When** the menu opens, **Then** they are not shown in this intent

## Technical Notes

- `share_plus` with the content URI.
- One `showSongMenu(context, track)` helper used by every list.

## Dependencies

### Requires
- 012-albums
- 013-artists
- 014-favorites
- 015-playlists

### Enables
- 018-track-multi-select

## Edge Cases

| Scenario | Expected Behavior |
|----------|-------------------|
| Hide the track that is playing | It keeps playing; it is not queued again |

## Out of Scope

- View lyrics, edit info (003, later)
