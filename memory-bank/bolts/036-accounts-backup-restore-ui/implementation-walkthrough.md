---
stage: implement
bolt: 036-accounts-backup-restore-ui
created: 2026-10-30T11:48:00Z
---

## Implementation Walkthrough: accounts-backup-restore-ui (bolt 6 of 8)

### Summary

- **Daily auto backup** runs three ways:
  - from a WorkManager task on Android, also with the app closed
  - from iOS background refresh, best effort
  - whenever the app opens or comes back to the foreground
- **It needs** Auto backup on, a signed-in user, Wi-Fi or Ethernet, and at least 24
  hours since the last backup.
- **It skips** an unchanged library, and never replaces another phone's backup.

### Structure Overview

- `features/account/application/auto_backup.dart`: the rule, the runner, and the
  in-app trigger.
- `features/account/application/auto_backup_task.dart`: scheduling and the
  background entry point.
- `main.dart` schedules the task after `runApp`. `ZemaApp` watches
  `autoBackupProvider`.
- iOS: `Info.plist` and `AppDelegate.swift`.

### Completed Work

- [x] **`autoBackupDue(status, now)`** and **`runAutoBackup(...)`**.
  - The cheap checks run first: signed in, then due, then Wi-Fi.
  - Then `backUp(skipUnchanged: true)`.
- [x] **`isUnmetered()`**: `connectivity_plus` reports Wi-Fi or Ethernet.
- [x] **`autoBackupProvider`**:
  - It registers a `ReceivePort` as `zema.autoBackup`, removed on dispose.
  - It runs the check through an `AppLifecycleListener.onResume`, and whenever
    `authUserProvider` yields a user (`fireImmediately`).
  - One run at a time. S25b's status is refreshed afterwards.
- [x] **`scheduleAutoBackup()`**:
  - It only runs on Android and iOS, in builds with a backend.
  - It registers the periodic task: every 6 hours, `NetworkType.unmetered`,
    `ExistingPeriodicWorkPolicy.update`. Errors are logged.
- [x] **`autoBackupDispatcher` / `runAutoBackupTask()`**:
  - If the app's port exists, it sends to it and returns.
  - Otherwise it uses its own `SupabaseAuthRepository`, opening the saved
    session from secure storage.
  - It closes the database and the client when done.
  - It always returns true; failures are recorded in the status instead.
- [x] **iOS**:
  - the BGTaskScheduler ID and the `fetch` background mode
  - `WorkmanagerPlugin.setPluginRegistrantCallback`
  - `registerPeriodicTask(withIdentifier:earliestBeginInSeconds: 21600)`
- [x] **Test helpers**: `accountOverrides(onWifi:)` and `pumpZemaApp(onWifi:)`.
  Off Wi-Fi by default, so other tests never auto back up.

### Key Decisions

- **The port hand-off** keeps one Supabase client per session in a process (see
  the plan).
- **No initial delay.** The first run comes soon after scheduling and finds
  nothing due, because opening the app just checked. A delay would block forced
  runs when checking by hand.
- **`update` instead of `keep`**, so a changed schedule applies after an app update.

### Deviations from Plan

- **The initial delay was dropped** after the emulator check (see Key Decisions).

### Dependencies Added

- [x] `workmanager` ^0.10.10 (Android WorkManager, iOS BGTaskScheduler)
- [x] `connectivity_plus` ^7.3.2

### Developer Notes

- **Forcing the job on Android 14+** needs its namespace:
  `adb shell cmd jobscheduler run -f -n androidx.work.systemjobscheduler com.zemaapp.zema <id>`
  The ID is in `dumpsys jobscheduler`.
- **WorkManager won't run a periodic job before its period, even when forced.**
  Move the clock forward with `cmd alarm set-time` (`auto_time` off), and restore
  it afterwards.
- **A small race remains:** the app opening at the very moment a cold background
  task refreshes the session.
