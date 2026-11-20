---
id: 003-render-clip
unit: 002-clip-maker
intent: 011-share-lyrics-clips
status: complete
priority: must
created: '2026-11-20T18:00:00Z'
assigned_bolt: 067-clip-render-share
implemented: true
---

# Story: 003-render-clip

Make the video

**As a** listener
**I want** my clip to look good with the lyrics in time
**So that** it is worth sharing

## Acceptance Criteria

- [ ] **Given** a selection, **When** I tap Make video, **Then** one frame per line change is painted with the default look (see 007): blurred cover art (or letter tile), the current line large and the next dimmed, title and artist at the top, the Zema mark
- [ ] **Given** Ethiopic lyrics, **When** painted, **Then** they use Noto Sans Ethiopic and never show boxes
- [ ] **Given** a render, **When** it runs, **Then** progress shows, Cancel works, and it works offline
