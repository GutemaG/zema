---
stage: plan
bolt: 035-accounts-backup-restore-ui
created: 2026-10-30T11:28:00Z
---

## Implementation Plan: accounts-backup-restore-ui (Back up now, S25b)

### Objective

S25b shows when this phone last backed up and any error. It offers Back up now and
the Auto backup switch. A backup that another phone made is replaced only after a
warning.

### Deliverables

- **`BackupRepository` in `zema_core`**:
  - `savedAt()`: the time only.
  - `fetch()`: the document and its time.
  - `save(document)`: returns the server's time.
- **`SupabaseBackupRepository` in `zema_data`**:
  - It reads the user's own `backups` row and saves through `save_backup`.
  - Failures are mapped by `run`.
- **`BackupStatus`**, per user in shared preferences (`backup.<userId>`):
  - the last backup time and the last error (offline, failed, or another phone's
    backup)
  - Auto backup (on by default)
  - `syncedAt`: the cloud time of the backup this phone last saved or restored
  - a hash of the last content
- **`BackupService`**, plain Dart so bolt 036's background task can use it:
  - It builds the document and compares the cloud's `savedAt` with `syncedAt`.
  - If they differ, it stops with `otherBackup` unless `replace` is set.
  - Otherwise it saves and records the result.
  - With `skipUnchanged` (auto backup), an unchanged hash uploads nothing.
- **`backupProvider`** (S25b's state) with `backUpNow({replace})` and
  `setAutoBackup`.
- **S25b**:
  - A Backup group: the last backup (or Never), the error line, Back up now (a
    spinner while running), and Auto backup.
  - Back up now shows "Backed up", or a message when offline or failed.
  - For another phone's backup: a warning naming its date, with Cancel and Replace.
- **Profile**: a Backup & sync row for signed-in users.
- **Delete account**: also forgets the backup status. Sign-out keeps it.

### Technical Approach

- **"Another phone's backup"** means the cloud has a time this phone never saved or
  restored. That also covers Start fresh (bolt 038), and a reinstall that lost the
  status.
- **Times are the server's**, so the two phones' clocks don't matter.
- **The Restore row** joins S25b in bolt 038, when S26 exists.

### Acceptance Criteria

- [ ] Last backup time or Never, the last error, Auto backup, and Back up now.
  Restore comes in 038.
- [ ] Online, Back up now uploads and updates the time.
- [ ] Offline or on failure, a message shows and the cloud is unchanged.
- [ ] Another phone's backup → a warning before replacing it.
- [ ] On the emulator, the server row matches the phone's data.
