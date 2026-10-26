---
intent: 003-lyrics-engine-and-display
created: 2026-10-23T22:16:40Z
completed: 2026-10-26T13:45:21Z
status: complete
---

# Inception Log: 003-lyrics-engine-and-display

## Overview

**Intent**: Synced lyrics for local songs from bundled sample data; sync engine and Ethiopic search
**Type**: New Feature (green-field)
**Created**: 2026-10-23T22:16:40Z
**Source**: `docs/roadmap.md` (see requirements.md header for screen/doc references)

## Artifacts Created

| Artifact | Status | File |
|----------|--------|------|
| Requirements | ✅ approved (Checkpoint 2) | requirements.md |
| System Context | ✅ | system-context.md |
| Units | ✅ | units.md, units/001-lyrics-engine-and-display-ui/unit-brief.md |
| Stories | ✅ | units/001-lyrics-engine-and-display-ui/stories/001–016 |
| Bolt Plan | ✅ | memory-bank/bolts/009–017-lyrics-engine-and-display-ui/ |

## Summary

| Metric | Count |
|--------|-------|
| Functional Requirements | 13 |
| Non-Functional Requirements | 5 (performance, quality) |
| Units | 1 |
| Stories | 16 |
| Bolts Planned | 9 |

## Units Breakdown

| Unit | Stories | Bolts | Priority |
|------|---------|-------|----------|
| 001-lyrics-engine-and-display-ui | 16 | 9 | Must |

## Decision Log

| Date | Decision | Rationale | Approved |
|------|----------|-----------|----------|
| 2026-10-23T22:16:40Z | Intent created as draft from roadmap stage | All 8 roadmap stages created up front; elaborated in order | Yes |
| 2026-10-26T13:41:09Z | Sample lyrics: original placeholder songs written for Zema; real songs later in the same format | No rights issues; unblocks planning | Yes |
| 2026-10-26T13:41:09Z | Transliteration: informal Latin spellings via rule table + fuzzy score | Matches how people type | Yes |
| 2026-10-26T13:41:09Z | Home (and Search) built first, in this intent | Removes the remaining "Coming soon" tabs that need no backend; Contribute stays until 006 | Yes |
| 2026-10-26T13:41:09Z | Sample timings written as LRC, with an importer | Easy to hand-write; reads users' LRC later | Yes |
| 2026-10-26T13:41:09Z | Requirements approved (Checkpoint 2) with the recommended answers | Product owner: "go with your recommendations" | Yes |
| 2026-10-26T13:41:09Z | Single frontend unit, 9 small bolts (009–017) of 1–2 stories | Product owner asked for smaller bolts that finish in one session | Yes (Checkpoint 3) |

## Scope Changes

| Date | Change | Reason | Impact |
|------|--------|--------|--------|

## Ready for Construction

**Checklist**:
- [x] All requirements documented
- [x] System context defined
- [x] Units decomposed
- [x] Stories created for all units
- [x] Bolts planned
- [x] Human review complete

## Next Steps

1. Checkpoint 3: review artifacts
2. Construction: bolt 009 (Home) via `/specsmd-construction-agent`

## Dependencies

001, 002.
