---
intent: 004-cloud-lyrics-catalog
created: 2026-10-23T22:16:40Z
completed: 2026-10-29T06:02:07Z
status: complete
---

# Inception Log: 004-cloud-lyrics-catalog

## Overview

**Intent**: Shared online lyrics catalog (read-only) with offline cache
**Type**: New Feature (green-field)
**Created**: 2026-10-23T22:16:40Z
**Source**: `docs/roadmap.md` (see requirements.md header for screen/doc references)

## Artifacts Created

| Artifact | Status | File |
|----------|--------|------|
| Requirements | ✅ approved | requirements.md |
| System Context | ✅ | system-context.md |
| Units | ✅ 2 units | units/ |
| Stories | ✅ 14 stories | units/*/stories/ |
| Bolt Plan | ✅ 11 bolts (018–028) | memory-bank/bolts/ |

## Summary

| Metric | Count |
|--------|-------|
| Functional Requirements | 11 |
| Non-Functional Requirements | see requirements.md |
| Units | 2 |
| Stories | 14 |
| Bolts Planned | 11 |

## Units Breakdown

| Unit | Stories | Bolts | Priority |
|------|---------|-------|----------|
| 001-cloud-lyrics-catalog-backend | 6 | 018–021 | Must |
| 002-cloud-lyrics-catalog-ui | 8 | 022–028 | Must/Should/Could |

## Decision Log

| Date | Decision | Rationale | Approved |
|------|----------|-----------|----------|
| 2026-10-23T22:16:40Z | Intent created as draft from roadmap stage | All 8 roadmap stages created up front; elaborated in order | Yes |
| 2026-10-29T05:57:07Z | Seed from files (LRC + index), starting with the 3 placeholder songs | Owner decision; no third-party lyrics without permission | Yes |
| 2026-10-29T05:57:07Z | Guests may report wrong lyrics, 5 per device per day | Owner decision | Yes |
| 2026-10-29T05:57:07Z | Local Supabase during development | Free, testable, no account; hosted later | Yes |
| 2026-10-29T05:57:07Z | Light song index on the phone; lyrics on demand + cache | Keeps auto-linking and title search offline | Yes |
| 2026-10-29T05:57:07Z | Bundled samples move to the backend | One source of lyrics; samples stay as test fixtures | Yes |
| 2026-10-29T05:57:07Z | All Should/Could features in scope | Owner decision | Yes |
| 2026-10-29T05:59:04Z | Requirements approved (Checkpoint 2) | Owner review | Yes |
| 2026-10-29T05:59:04Z | 2 units: backend + ui, both simple-construction-bolt | Backend is SQL/scripts; built and tested on its own first | Yes |
| 2026-10-29T06:02:07Z | Artifacts approved (Checkpoint 3) | Owner review | Yes |

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

1. Start construction with bolt 018 (local Supabase + schema)

## Dependencies

003 (complete). Open decision on seeding resolved.
