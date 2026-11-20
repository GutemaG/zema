---
intent: 011-share-lyrics-clips
phase: inception
status: units-decomposed
updated: 2026-11-20T18:00:00Z
---

# Share Lyrics Clips - Unit Decomposition

### Unit 1: 001-clip-encoder
Android: cut audio and encode frames to a 1080×1920 MP4, with progress and cancel.
**Stories**: 001-encode-clip

### Unit 2: 002-clip-maker
Flutter: the clip editor, the frame painter, the look, render, share and save.
**Stories**: 002-pick-clip, 003-render-clip, 004-share-clip, 007-clip-look, 005-text-only-clip, 006-lyrics-only-clip

## Bolts

| Bolt | Unit | Stories |
|------|------|---------|
| 065-clip-encoder | 1 | 001 (timing gate on the owner's phone) |
| 066-clip-editor | 2 | 002 |
| 067-clip-render-share | 2 | 003, 004 |
| 068-clip-look | 2 | 007 |
| 069-clip-extras | 2 | 005, 006 |
