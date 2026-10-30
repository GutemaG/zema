---
stage: plan
bolt: 036-accounts-backup-restore-ui
created: 2026-10-30T11:43:00Z
---

## Implementation Plan: accounts-backup-restore-ui (daily auto backup)

### Objective

With Auto backup on, the phone backs up at most once a day on Wi-Fi:
- **Android:** with the app closed (WorkManager).
- **iOS:** best effort through background refresh.
- **Both:** whenever the app opens or returns to the foreground. It never uploads
  an unchanged library, and never replaces another phone's backup.

### Deliverables

- **Packages**:
  - `workmanager` ^0.10.10: Android WorkManager and iOS BGTaskScheduler.
  - `connectivity_plus` ^7.3.2: the Wi-Fi check.
- **`auto_backup.dart`**:
  - **`autoBackupDue`**: Auto backup is on, and the last backup was at least 24
    hours ago, or never.
  - **`runAutoBackup`** does nothing when signed out, not due, or not on
    Wi-Fi/Ethernet. Otherwise it runs `BackupService.backUp(skipUnchanged: true)`.
  - **`autoBackupProvider`**, kept alive by `ZemaApp`, runs it:
    - when the signed-in user is known at start
    - on every return to the foreground
    - when the background task asks through a port named in `IsolateNameServer`
  - **`unmeteredNetworkProvider`**: a test seam.
- **`auto_backup_task.dart`**:
  - **`scheduleAutoBackup()`**, called from `main`, registers a periodic task:
    every 6 hours, on unmetered networks, with the `update` policy.
  - **The dispatcher**:
    - If the app is running in this process, it asks the app over the port.
    - Otherwise it opens the database, preferences and the saved session itself,
      and runs `runAutoBackup`.
- **iOS**:
  - `Info.plist`: `BGTaskSchedulerPermittedIdentifiers`
    (`com.zemaapp.zema.autoBackup`) and `UIBackgroundModes` `fetch`.
  - `AppDelegate`: the plugin registrant for the background engine, and the
    periodic task's handler.

### Technical Approach

- **One session per process.** Supabase rotates refresh tokens. If two clients
  refreshed the same session, one could reuse a rotated token and get it revoked.
  So when the app's isolate is alive, for example playing music, it makes the
  backup.
- **The background task checks every 6 hours.** The 24-hour rule sits in Dart, so
  backups come every 24 to 30 hours, never more than once a day.
- **Never replaced automatically.** Another phone's backup is recorded as an error
  for S25b to show.

### Acceptance Criteria

- [ ] **Android:** with the app closed, on Wi-Fi, a WorkManager task backs up at
  most once a day.
- [ ] **On open:** over 24 hours since the last backup → it backs up on Wi-Fi.
  Background refresh also tries on iOS.
- [ ] **Nothing is uploaded** when Auto backup is off, the user is signed out, or
  the phone is on mobile data.
- [ ] **An unchanged library** is not uploaded.
- [ ] **On the emulator**, a forced run with the app closed lands a backup.
