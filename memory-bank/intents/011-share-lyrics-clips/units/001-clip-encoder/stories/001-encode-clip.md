---
id: 001-encode-clip
unit: 001-clip-encoder
intent: 011-share-lyrics-clips
status: ready
priority: must
created: '2026-11-20T18:00:00Z'
assigned_bolt: 065-clip-encoder
implemented: false
---

# Story: 001-encode-clip

Encode a clip

**As a** listener
**I want** a 60 s clip of my song made on my phone
**So that** I can share it without waiting long

## Acceptance Criteria

- [ ] **Given** a local file, a start and end, and frames with their times, **When** encoded, **Then** the MP4 is 1080×1920, 30 fps, H.264 + AAC, as long as the selection, each frame shown from its time (±0.2 s)
- [ ] **Given** a render, **When** it runs, **Then** progress is reported and Cancel stops it and deletes the partial file
- [ ] **Given** a phone that can't encode 1080×1920, **When** encoding starts, **Then** it falls back to 720×1280
- [ ] **Given** the owner's phone, **When** a 60 s clip is made, **Then** it takes under 30 s (time recorded in the bolt)
