---
stage: implement
bolt: 035-accounts-backup-restore-ui
created: 2026-10-30T11:33:00Z
---

## Implementation Walkthrough: accounts-backup-restore-ui (bolt 5 of 8)

### Summary

- **S25b** now shows:
  - the last backup (or Never) and the last error
  - Back up now
  - Auto backup, whose switch is saved now and acted on in bolt 036
- **The backup** uploads to the user's private row on the server. A backup made by
  another phone is replaced only after the user confirms.
- **Profile** links to Backup & sync.

### Structure Overview

- **`zema_core`**: `backup/backup_repository.dart` (`BackupRepository`,
  `StoredBackup`).
- **`zema_data`**: `supabase_backup_repository.dart`.
- **App**:
  - `features/account/data/backup_status.dart`: `BackupStatus` and
    `BackupStatusStore`
  - `application/backup_service.dart`: `BackupService`, `BackupOutcome` and
    `backupContentHash`
  - `application/backup.dart`: providers and `BackupController`
  - `presentation/backup_screen.dart`

### Completed Work

- [x] **`SupabaseBackupRepository`**:
  - `savedAt` and `fetch` read the user's own `backups` row through lists, not
    `maybeSingle`.
  - `save` calls `save_backup` and returns the server's time.
  - A document that isn't an object, or has a newer format, throws
    `BackupFormatFailure`.
- [x] **`BackupStatus`** is stored as JSON at `backup.<userId>`.
  - Unreadable values fall back to the defaults.
  - `read` reloads preferences, so a background backup is seen.
- [x] **`BackupService.backUp(userId, {replace, skipUnchanged})`** returns
  `(outcome, otherSavedAt)` and always writes the status:
  - `done` sets the time, `syncedAt` and the hash, and clears the error.
  - `offline` and `failed` keep the old time and record the error.
  - `otherBackup` records the error and uploads nothing.
- [x] **`backupContentHash`**: FNV-1a over the JSON without `createdAt`.
- [x] **`BackupController`**:
  - The signed-in user's status, read from the cache when built.
  - `backUpNow` returns null when it's already running or the user is signed out.
  - `setAutoBackup` and `refresh`.
- [x] **S25b**:
  - The Backup group: Last backup, the error line in the error color, Back up now
    with a spinner, and Auto backup ("Daily on Wi-Fi" with a switch).
  - The Replace dialog names the cloud backup's date.
  - Messages are looked up before the action runs.
  - Times use `MaterialLocalizations` (medium date and time of day).
- [x] **Profile**: a Backup & sync row above Settings, for signed-in users.
- [x] **Delete account** also removes `backup.<userId>`.
- [x] **Test helpers**: `FakeBackupRepository` (failures, a save gate, a clock),
  wired into `accountOverrides` and `pumpZemaApp(backups:)`.
- [x] **Strings**: 16 new English strings.

### Key Decisions

- **`syncedAt` decides "another phone's backup"**: the cloud's time is compared with
  the time this phone last saved or restored. It needs no device IDs, and it covers
  Start fresh and reinstalls.
- **Sign-out keeps the status.** Signing back in on the same phone doesn't warn
  about its own backup.
- **`MaterialLocalizations` for dates.** `intl` has no date data for Oromo or
  Tigrinya, and the Material ones fall back safely.
- **No device name** is sent (`save_backup`'s `device` stays null). Nothing reads it
  yet.

### Deviations from Plan

- **The Restore row comes in bolt 038**, together with S26, which it opens.
- **During a manual Back up now, the "another phone" error line shows behind the
  warning dialog.** It's accurate if the user cancels.

### Dependencies Added

- None.
