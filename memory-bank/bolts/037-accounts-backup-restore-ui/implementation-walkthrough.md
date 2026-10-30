---
stage: implement
bolt: 037-accounts-backup-restore-ui
created: 2026-10-30T12:13:00Z
---

## Implementation Walkthrough: accounts-backup-restore-ui (bolt 7 of 8)

### Summary

- **Backed-up songs are found again** on this phone by file name and length, or by
  title, artist and length.
- **A backup merges** into the library in one transaction, adding and never
  removing, and the backup's settings are applied afterwards.
- **Entries whose song isn't on this phone** are reported, ready for bolt 038 to
  keep and show.

### Structure Overview

- **`zema_core/src/backup/`**:
  - `backup_matcher.dart` (`BackupTrackMatcher`, `matchDurationTolerance`)
  - `unmatched_entry.dart` (`UnmatchedEntry`, `BackupEntryKind`)
  - `storageRelativePath` in `track_identity.dart`
- **`app/database/restore_dao.dart`**: `RestoreDao` and `RestoreReport`.
- **`features/account/application/restore.dart`**: `backupRestorerProvider`.
- **`SettingsController.replaceAll`**.

### Completed Work

- [x] **`BackupTrackMatcher`**:
  - Two hash maps: lower-case file name to tracks, and normalized
    "title␀artist" to tracks.
  - A lookup picks the closest length within the tolerance.
  - An empty normalized title or artist is never a key.
- [x] **`UnmatchedEntry`**: one constructor per kind, with value equality.
- [x] **`RestoreDao.merge`**:
  - Favorites, playlists, manual lyrics links, and hidden folders and songs, as
    planned.
  - Counts are made against the rows already there, so a second restore adds
    nothing.
  - The playlist's local name and order are kept.
- [x] **`RestoreReport.songsNotFound`**: the songs not found, each once.
- [x] **`BackupRestorer.restore(document, keepUnmatched:)`**.
- [x] **`SettingsController.replaceAll`**: each setter, which skips unchanged
  values. A missing language keeps the current one.

### Key Decisions

- **Search normalization for tags**, as the story suggests. "ሠላም" matches "ሰላም", and
  "Tizita (Live)" matches "tizita - live".
- **Missing tracks never match.** A restore shouldn't attach entries to files that
  are gone, since the file may never come back.
- **Hidden folders without a match** use the main storage path, so they're hidden
  as soon as the folder appears.
- **Settings after the transaction.** Preferences can't share Drift's transaction,
  so they're applied only once the library merge has succeeded.

### Deviations from Plan

- None.

### Dependencies Added

- None.
