---
intent: 011-share-lyrics-clips
created: 2026-10-29T15:44:10Z
completed: 2026-11-20T18:00:00Z
status: complete
---

# Inception Log: 011-share-lyrics-clips

Share part of a song (60 s, up to 2 min) as a portrait video with synced lyrics.

| Artifact | File |
|----------|------|
| Requirements | requirements.md (approved) |
| System Context | system-context.md |
| Units | units.md, units/ (2 units, 7 stories) |
| Bolts | bolts 065–069 |

## Decision Log

| Date | Decision |
|------|----------|
| 2026-10-29 | Intent created as draft |
| 2026-11-20 | 60 s default, up to 2 min; Zema mark on, can be turned off; no song link; Android first with native MediaCodec + MediaMuxer (no FFmpeg); iOS later |
| 2026-11-20 | The user chooses background, text and transparency (all with defaults), artist and album names, and album and artist pictures (story 007, bolt 068) |

## Dependencies

002 (player) and 003 (synced lyrics), both complete.
