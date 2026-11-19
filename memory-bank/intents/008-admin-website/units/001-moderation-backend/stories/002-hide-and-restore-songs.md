---
id: 002-hide-and-restore-songs
unit: 001-moderation-backend
intent: 008-admin-website
status: complete
priority: must
created: '2026-11-19T10:00:00Z'
assigned_bolt: 054-moderation-backend
implemented: true
---

# Story: 002-hide-and-restore-songs

Hide and restore songs

**As a** moderator
**I want** to hide a bad song and bring it back
**So that** listeners stop seeing it without losing it

## Acceptance Criteria

- [x] **Given** a moderator, **When** they call `moderator_songs(query, limit, offset)`, **Then** approved and hidden songs matching title or artist come back with status, version and line count
- [x] **Given** a moderator, **When** they call `set_song_hidden(id, hidden)`, **Then** the song gets status `hidden` (new enum value) or back to `approved`; phones drop it when they next fetch the index (no version bump needed; restoring keeps `approved_at`)
- [x] **Given** a hidden song, **When** a phone reads `song_index` or `get_song`, **Then** it isn't there, and approving a contribution to it is refused with `unknown_song` (the existing check)
- [x] **Given** pgTAP, **When** run, **Then** hiding, restoring, the index and roles are tested
