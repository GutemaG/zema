---
intent: 005-accounts-backup-restore
created: 2026-10-23T22:16:40Z
completed: 2026-10-29T19:09:38Z
status: complete
---

# Inception Log: 005-accounts-backup-restore

## Overview

**Intent**: Optional Google sign-in with backup and restore across phones
**Type**: New Feature (green-field)
**Created**: 2026-10-23T22:16:40Z
**Source**: `docs/roadmap.md` (see requirements.md header for screen/doc references)

## Artifacts Created

| Artifact | Status | File |
|----------|--------|------|
| Requirements | ✅ approved | requirements.md |
| System Context | ✅ | system-context.md |
| Units | ✅ 2 units | units/ |
| Stories | ✅ 16 stories | units/*/stories/ |
| Bolt Plan | ✅ 10 bolts (029–038) | memory-bank/bolts/ |

## Summary

| Metric | Count |
|--------|-------|
| Functional Requirements | 10 |
| Non-Functional Requirements | see requirements.md |
| Units | 2 |
| Stories | 16 |
| Bolts Planned | 10 |

## Units Breakdown

| Unit | Stories | Bolts | Priority |
|------|---------|-------|----------|
| 001-accounts-backend | 4 | 029–030 | Must |
| 002-accounts-backup-restore-ui | 12 | 031–038 | Must/Should |

## Decision Log

| Date | Decision | Rationale | Approved |
|------|----------|-----------|----------|
| 2026-10-23T22:16:40Z | Intent created as draft from roadmap stage | All 8 roadmap stages created up front; elaborated in order | Yes |
| 2026-10-29T16:20:00Z | Restore merges into local data; settings come from the backup | Owner decision; nothing local is lost | Yes |
| 2026-10-29T16:20:00Z | Backup is one versioned JSON document per user | Owner decision; simple, small, extendable by 006/007 | Yes |
| 2026-10-29T16:20:00Z | Profile stats hidden until 006 | Owner decision | Yes |
| 2026-10-29T16:20:00Z | No Google Cloud project yet: sign-in built against a fake, setup guide written | Owner has no project yet | Yes |
| 2026-10-29T16:20:00Z | Delete account added (FR-4) | Required by the App Store and Google Play for apps with accounts | Yes |
| 2026-10-29T16:20:00Z | S04 shown once, also to existing installs, before Home (no onboarding yet) | Fits the current app | Yes |
| 2026-10-29T19:05:45Z | Requirements approved (Checkpoint 2) | Owner review | Yes |
| 2026-10-29T19:05:45Z | Roles reuse the existing `user_roles` table | Already in the 004 schema | Yes |
| 2026-10-29T19:05:45Z | 2 units: backend + ui, both simple-construction-bolt | Same split as 004; sign-in bolts before backup | Yes |
| 2026-10-29T19:09:38Z | Artifacts approved (Checkpoint 3) | Owner review | Yes |

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

1. Start construction with bolt 029 (profiles, roles, Google auth config)

## Dependencies

002 (track identity), 004 (backend).
