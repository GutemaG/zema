---
intent: 013-track-identification
created: 2026-11-19T16:00:00Z
status: complete
---

# Inception Log: 013-track-identification

| Artifact | File |
|----------|------|
| Requirements (6 FR) | requirements.md |
| System context | system-context.md |
| Units (4), stories (7) | units.md, units/ |
| Bolts | 058–059-track-print-core, 060-track-print-backend, 061-track-print-app, 062-track-print-review |

## Decision Log

| Date | Decision | Rationale |
|------|----------|-----------|
| 2026-11-19 | No third-party identification | Owner's choice |
| 2026-11-19 | Compact whole-track print, not landmark hashes, on the server | ~4–10 KB vs ~4 MB per song; bitrate test separated copies from different songs |
| 2026-11-19 | Title matches share prints | The well-tagged majority fills the catalog for the rest |
| 2026-11-19 | Prints per song, several allowed | Files linked by title have no recording |
| 2026-11-19 | Eval gate in bolt 059: passed (worst copy 17.5 %, closest different file 48.6 %) | Shifted starts scored worst (12–13 %); confirm before building on it |

## Status

Complete (bolts 058–062, 2026-11-20). The production migration was applied on 2026-11-19.
