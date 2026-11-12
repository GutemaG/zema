---
intent: 009-audio-fingerprint-library
created: 2026-10-29T08:29:54Z
completed: null
status: in-progress
---

# Inception Log: 009-audio-fingerprint-library

## Overview

**Intent**: Know which song is playing (by sound, online or offline, or from other apps' media sessions) and show its lyrics at the current line, in Zema or in a floating window
**Type**: New Feature (green-field)
**Created**: 2026-10-29T08:29:54Z
**Source**: product owner request, 2026-10-29 (see requirements.md header)

## Artifacts Created

| Artifact | Status | File |
|----------|--------|------|
| Requirements | 📝 draft | requirements.md |
| System Context | ⬜ | system-context.md |
| Units | ⬜ | units/ |
| Stories | ⬜ | units/*/stories/ |
| Bolt Plan | ⬜ | memory-bank/bolts/ |

## Summary

| Metric | Count |
|--------|-------|
| Functional Requirements | 19 (FR-0 to FR-18, draft) |
| Non-Functional Requirements | see requirements.md |
| Units | 0 |
| Stories | 0 |
| Bolts Planned | 0 |

## Units Breakdown

| Unit | Stories | Bolts | Priority |
|------|---------|-------|----------|

## Decision Log

| Date | Decision | Rationale | Approved |
|------|----------|-----------|----------|
| 2026-10-29T08:29:54Z | Intent created as draft | Identify songs by their sound; only fingerprints stored, never audio | Yes |
| 2026-11-03T12:17:22Z | Scope widened: tap-to-listen, lookup from any point with position, lyrics at the current line, History | Product owner: must work like Musixmatch / Pixel | Yes |
| 2026-11-03T12:40:00Z | 007 merged in as Part B; open questions decided (offline Listen Must, lock-screen tile and widget Must, opt-in library fingerprints) | Product owner | Yes |

## Scope Changes

| Date | Change | Reason | Impact |
|------|--------|--------|--------|
| 2026-11-03 | Listen button, lyrics from a match and History moved in from 010 | Identification from the microphone is a must | 010 keeps only keep-listening |
| 2026-11-03 | 007 merged in (Part B) | Related; one lyrics view and floating window | 007 closed as merged |

## Ready for Construction

**Checklist**:
- [ ] All requirements documented
- [ ] System context defined
- [ ] Units decomposed
- [ ] Stories created for all units
- [ ] Bolts planned
- [ ] Human review complete

## Next Steps

1. Resolve open questions in requirements.md
2. Run requirements skill (Checkpoints 1–2) via `/specsmd-inception-agent`

## Dependencies

004 (catalog, recordings); 006 (contributors submit fingerprints). Includes former 007 (needs 003). 010 builds on this intent.
