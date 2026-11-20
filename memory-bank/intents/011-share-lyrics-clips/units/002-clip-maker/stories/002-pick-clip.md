---
id: 002-pick-clip
unit: 002-clip-maker
intent: 011-share-lyrics-clips
status: ready
priority: must
created: '2026-11-20T18:00:00Z'
assigned_bolt: 066-clip-editor
implemented: false
---

# Story: 002-pick-clip

Pick the clip

**As a** listener
**I want** to choose which part of a song to share
**So that** the clip shows the moment I want

## Acceptance Criteria

- [ ] **Given** a library track linked to lyrics, **When** I tap Share clip (Now Playing, song detail, song menu), **Then** the editor opens with a 60 s selection at the current position or the first line
- [ ] **Given** the handles, **When** I drag them, **Then** they snap to line starts and the selection stays between 5 s and 2 min, inside the track
- [ ] **Given** a selection, **When** I tap Play, **Then** exactly that part plays and the lines light up in time
- [ ] **Given** a screen reader or 1.3× text, **When** I use the editor, **Then** the handles can be moved with buttons and read their times
