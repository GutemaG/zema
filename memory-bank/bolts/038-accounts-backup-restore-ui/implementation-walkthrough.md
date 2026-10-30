---
stage: implement
bolt: 038-accounts-backup-restore-ui
created: 2026-10-30T12:35:00Z
---

## Implementation Walkthrough: accounts-backup-restore-ui (bolt 8 of 8)

### Summary

- **S26** offers a cloud backup after sign-in, and from Backup & sync.
  - Restore merges it and lists the songs that aren't on this phone.
  - Start fresh leaves everything as it is.
- **Songs not found** are kept in a new table. Backups still include them, and
  they're added once a scan finds them.

### Structure Overview

- **Database**:
  - `app/database/tables.dart`: `UnmatchedEntries`
  - `unmatched_dao.dart`
  - schema v7: `drift_schemas/zema/drift_schema_v7.json`, generated steps and test
    schema
- **`features/account/application/restore.dart`**:
  - `BackupRestorer` (restore, `retryUnmatched`)
  - `unmatchedRetryProvider`
  - `restoreToOffer`
  - `RestoreController` and its states
- **`features/account/presentation/restore_screen.dart`**: S26.
- **Changes elsewhere**:
  - `BackupBuilder`: puts the kept entries back in
  - `AccountActionsController._forget`: clears them
  - S24: offers S26
  - S25b: the Restore row
  - routes: `/restore`
  - `ZemaApp`: keeps the retry provider alive

### Completed Work

- [x] **The table and migration**: v6 → v7 creates the table, and the
  data-integrity migration test passes.
- [x] **`UnmatchedDao`**: rows map to `UnmatchedEntry`; an unknown kind is skipped.
- [x] **Restore** keeps entries not found by default, in the same transaction.
- [x] **`retryUnmatched`**:
  - It builds a document from the kept entries, using only playlists that still
    exist.
  - It merges, then keeps the original entries whose songs are still missing.
- [x] **The builder** adds kept favorites, choices and hidden songs once each.
  Playlist entries go back to their old position, clamped to the end.
- [x] **S26**:
  - Loading, Found, None, Error (offline, failed or newer), Running (with "Finding
    the songs on this phone…" while scanning) and Done.
  - A close button when opened from S04.
  - Back is blocked while restoring.
- [x] **S24**: S26 opens in S24's place; the "Signed in as" message isn't shown
  then, because it would cover S26's buttons.
- [x] **Strings**: 25 new English strings.

### Key Decisions

- **Retry by merging again.** The kept entries become a small backup document and
  go through the same transaction as a restore, so there is one merge.
- **"Not seen by this phone" means `syncedAt` differs from the cloud's time**, as
  in bolt 035.
  - Restoring sets `syncedAt`.
  - Start fresh doesn't, so a later Back up now warns first.
- **The kept entries belong to the account.** They're cleared on sign-out and
  delete, like the profile cache.

### Deviations from Plan

- **No "Signed in as" message when S26 opens** (found by tests): it covered S26's
  buttons.

### Dependencies Added

- None.
