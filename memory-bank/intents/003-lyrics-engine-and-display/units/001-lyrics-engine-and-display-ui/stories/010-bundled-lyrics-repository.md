---
id: 010-bundled-lyrics-repository
unit: 001-lyrics-engine-and-display-ui
intent: 003-lyrics-engine-and-display
status: complete
priority: must
created: 2026-10-26T13:41:09Z
assigned_bolt: 013-lyrics-engine-and-display-ui
implemented: true
---

# Story: 010-bundled-lyrics-repository

## User Story

**As a** listener
**I want** a few songs with lyrics available offline
**So that** I can try synced lyrics before the cloud catalog exists

## Acceptance Criteria

- [x] **Given** `LyricsRepository` in `zema_core`, **When** used, **Then** it lists songs, gets a song with its recordings and timings, and searches by normalized title
- [x] **Given** app assets, **When** the app starts, **Then** `BundledLyricsRepository` loads 3–5 placeholder songs (original text for Zema, Amharic and Afaan Oromoo) from LRC files
- [x] **Given** a script, **When** run, **Then** it generates matching test audio (tone + ID3 title/artist) to push to a device
- [x] **Given** a malformed asset, **When** loading, **Then** it is skipped and logged at FINE, the rest load

## Technical Notes

- `apps/mobile/assets/lyrics/`; script in `tool/`; audio not committed.

## Dependencies

### Requires
- 009-lrc-import

### Enables
- 011-track-song-linking

## Edge Cases

| Scenario | Expected Behavior |
|----------|-------------------|
| Duplicate song IDs | Second skipped |

## Out of Scope

- Cloud repository (004)
