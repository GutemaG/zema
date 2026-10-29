---
unit: 001-accounts-backend
intent: 005-accounts-backup-restore
created: 2026-10-29T19:10:38Z
last_updated: 2026-10-29T19:33:58Z
---

# Construction Log: accounts-backend

## Original Plan

**From Inception**: 2 bolts planned
**Planned Date**: 2026-10-29T19:05:45Z

| Bolt ID | Stories | Type |
|---------|---------|------|
| 029-accounts-backend | 001, 002 | simple-construction-bolt |
| 030-accounts-backend | 003, 004 | simple-construction-bolt |

## Replanning History

| Date | Action | Change | Reason | Approved |
|------|--------|--------|--------|----------|

## Current Bolt Structure

| Bolt ID | Stories | Status | Changed |
|---------|---------|--------|---------|
| 029-accounts-backend | 001, 002 | ✅ completed | - |
| 030-accounts-backend | 003, 004 | ✅ completed | - |

## Execution History

| Date | Bolt | Event | Details |
|------|------|-------|---------|
| 2026-10-29T19:10:38Z | 029-accounts-backend | started | Stage 1: plan |
| 2026-10-29T19:18:50Z | 029-accounts-backend | stage-complete | plan → implement |
| 2026-10-29T19:22:57Z | 029-accounts-backend | stage-complete | implement → test |
| 2026-10-29T19:26:34Z | 029-accounts-backend | completed | All 3 stages done; 331 pgTAP pass; 12/12 planted bugs caught |
| 2026-10-29T19:26:59Z | 030-accounts-backend | started | Stage 1: plan |
| 2026-10-29T19:27:59Z | 030-accounts-backend | stage-complete | plan → implement |
| 2026-10-29T19:29:48Z | 030-accounts-backend | stage-complete | implement → test |
| 2026-10-29T19:33:58Z | 030-accounts-backend | completed | All 3 stages done; 373 pgTAP pass; 16/16 planted bugs caught; backend unit complete |

## Notes
- Bolt 029: profiles + contributor role from a sign-up trigger; display_name is the only API write (column grant). Google provider on from supabase/.env (unset → env() text, tokens refused). An UPDATE with no WHERE is needed to test the update policy: a WHERE also applies the read policy.
- Bolt 030: backups saved only via save_backup (security definer, caller's row, server time, 2 MB → 54000); delete_account deletes auth.users and the cascades do the rest. now() is fixed in a transaction: back-date rows to test new times.
