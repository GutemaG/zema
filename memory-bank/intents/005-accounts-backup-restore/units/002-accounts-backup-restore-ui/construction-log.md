---
unit: 002-accounts-backup-restore-ui
intent: 005-accounts-backup-restore
created: 2026-10-29T19:36:08Z
last_updated: 2026-10-29T19:59:26Z
---

# Construction Log: accounts-backup-restore-ui

## Original Plan

**From Inception**: 8 bolts planned
**Planned Date**: 2026-10-29T19:05:45Z

| Bolt ID | Stories | Type |
|---------|---------|------|
| 031-accounts-backup-restore-ui | 001 | simple-construction-bolt |
| 032-accounts-backup-restore-ui | 002, 003 | simple-construction-bolt |
| 033-accounts-backup-restore-ui | 004, 005 | simple-construction-bolt |
| 034-accounts-backup-restore-ui | 006, 007 | simple-construction-bolt |
| 035-accounts-backup-restore-ui | 008 | simple-construction-bolt |
| 036-accounts-backup-restore-ui | 009 | simple-construction-bolt |
| 037-accounts-backup-restore-ui | 010 | simple-construction-bolt |
| 038-accounts-backup-restore-ui | 011, 012 | simple-construction-bolt |

## Replanning History

| Date | Action | Change | Reason | Approved |
|------|--------|--------|--------|----------|

## Current Bolt Structure

| Bolt ID | Stories | Status | Changed |
|---------|---------|--------|---------|
| 031-accounts-backup-restore-ui | 001 | ✅ completed | - |
| 032-accounts-backup-restore-ui | 002, 003 | ✅ completed | - |
| 033-accounts-backup-restore-ui | 004, 005 | planned | - |
| 034-accounts-backup-restore-ui | 006, 007 | planned | - |
| 035-accounts-backup-restore-ui | 008 | planned | - |
| 036-accounts-backup-restore-ui | 009 | planned | - |
| 037-accounts-backup-restore-ui | 010 | planned | - |
| 038-accounts-backup-restore-ui | 011, 012 | planned | - |

## Execution History

| Date | Bolt | Event | Details |
|------|------|-------|---------|
| 2026-10-29T19:34:10Z | 031-accounts-backup-restore-ui | started | Stage 1: plan |
| 2026-10-29T19:39:26Z | 031-accounts-backup-restore-ui | stage-complete | plan → implement |
| 2026-10-29T19:59:26Z | 031-accounts-backup-restore-ui | stage-complete | implement → test |
| 2026-10-29T19:59:26Z | 031-accounts-backup-restore-ui | completed | All 3 stages done; app 820, core 209, data 47 pass; 13/14 planted bugs caught (1 equivalent) |
| 2026-10-29T20:20:00Z | 032-accounts-backup-restore-ui | started | Stage 1: plan |
| 2026-10-29T20:21:31Z | 032-accounts-backup-restore-ui | stage-complete | plan → implement |
| 2026-10-29T20:31:00Z | 032-accounts-backup-restore-ui | stage-complete | implement → test |
| 2026-10-29T20:51:19Z | 032-accounts-backup-restore-ui | completed | All 3 stages done; app 861 pass; real Google sign-in on the emulator creates the profile; 16/16 planted bugs caught (1 after a new test) |
| 2026-10-30T08:38:00Z | 033-accounts-backup-restore-ui | started | Stage 1: plan |
| 2026-10-30T08:40:00Z | 033-accounts-backup-restore-ui | stage-complete | plan → implement |
| 2026-10-30T08:54:15Z | 033-accounts-backup-restore-ui | stage-complete | implement → test |
| 2026-10-30T09:32:30Z | 033-accounts-backup-restore-ui | completed | All 3 stages done; app 909, data 52 pass; profile, rename, sign out and delete account checked on the emulator (server rows gone); 19/19 planted bugs caught (2 after new tests) |

## Notes
- Bolt 031: restore() signs the saved user in at once and confirms in the background (gotrue retries ~10 s offline). Avoid postgrest maybeSingle(): it loses server error codes. Expired test sessions need a stand-in access token (expiry is read from the JWT).
- Bolt 032: the Google picker is a seam (FakeGoogleAccountPicker); tests have no picker by default, so S04 stays away. Android reports a SHA-1/package mismatch as a cancel. The iOS URL scheme comes from the gitignored ios/Flutter/Google.local.xcconfig (tool/google_env.sh).
- Bolt 033: an action that signs out removes S25's Account rows before it returns; look up the ScaffoldMessenger first. After delete (Google disconnect), the next sign-in shows Google's consent screen. Google photo URLs end in =s96-c; the avatar cache asks for =s256-c.
