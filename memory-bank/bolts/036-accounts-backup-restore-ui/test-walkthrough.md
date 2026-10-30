---
stage: test
bolt: 036-accounts-backup-restore-ui
created: 2026-10-30T12:07:54Z
---

## Test Report: accounts-backup-restore-ui (bolt 6 of 8)

### Summary

- **Tests**: app 974 (18 new), all passing. Analyze and format are clean.
- **On the Android emulator, against the local backend**:
  - **On open**: with the last backup two days old, opening the app backed up by
    itself (2 favorites).
  - **App closed**: the process was killed, the clock moved forward 7 hours, and the
    WorkManager job was forced. It backed up with the app closed (3 favorites), and
    WorkManager reported SUCCESS.
  - Afterwards the app was still signed in, and S25b showed the background
    backup's time with no error.
- **iOS simulator** (iPhone 18 Pro): the debug build compiles with `workmanager`,
  and the app launches to S04. This is the first iOS run in intent 005.
- **Planted bugs**: 12.
  - 11 caught.
  - One is equivalent: `fireImmediately` removed (see below).
  - One of the 11 got through the first run (the Wi-Fi rule); a new test catches
    it.

### Test Files

- [x] `test/features/account/auto_backup_test.dart` (18):
  - **`autoBackupDue`**:
    - Never backed up is due.
    - 23 h 59 min is not due; 24 h and 3 days are.
    - Never when Auto backup is off.
  - **`unmeteredConnection`**: Wi-Fi or Ethernet count, even alongside mobile data.
    Mobile, VPN, none and empty don't.
  - **`runAutoBackup`**:
    - Due on Wi-Fi, it backs up.
    - Nothing when signed out, on mobile data, or switched off.
    - Within a day it isn't even checked; a day later an unchanged library is
      skipped, and a changed one uploads.
    - Another phone's backup is never replaced, and the error is recorded.
  - **`runAutoBackupTask`**: with the app's port registered, it sends to the app
    and does nothing itself.
  - **In the app (the full app)**:
    - **When it runs**:
      - On open, signed in, on Wi-Fi: it backs up.
      - Coming back to the app, now on Wi-Fi: it backs up.
      - The background task's message: it backs up in the app.
    - **When it doesn't**:
      - Not on mobile data, when switched off, or for a guest.
      - Coming back the same day changes nothing.

### Acceptance Criteria Validation

- ✅ **Android, app closed, on Wi-Fi: WorkManager backs up at most once a day.**
  - A periodic task every 6 hours, on unmetered networks.
  - The 24-hour rule in `autoBackupDue`, by tests.
  - On the emulator, a forced run with the app's process dead.
- ✅ **When the app opens with the last backup over 24 hours old, it backs up on
  Wi-Fi; on iOS, background refresh also tries.**
  - The open and resume paths: tests, and the emulator.
  - On iOS:
    - The task is registered in `AppDelegate`, and `Info.plist` permits it.
    - The build launches on the simulator.
    - iOS decides when background refresh runs, so it wasn't forced.
- ✅ **Off, signed out or on mobile data: nothing is uploaded.** Tests.
- ✅ **Unchanged: nothing is uploaded.** Tests, using the content hash from bolt
  035.
- ✅ **On the emulator, a forced run with the app closed lands a backup.** The
  server row went from 11:51:56 (2 favorites) to 11:53:57 (3 favorites).

### Planted Bugs (12)

- **Caught (11)**:
  - due ignoring Auto backup
  - due every hour
  - no Wi-Fi check
  - uploading unchanged
  - replacing another phone's backup
  - no check on resume
  - the port's message ignored
  - the task not handing off to the app
  - the app not keeping the trigger
  - a guest backing up
  - the Wi-Fi rule counting mobile data: missed at first, caught after
    `unmeteredConnection` was split out and tested
- **Equivalent (1)**: dropping `fireImmediately`. The trigger starts before the
  saved session is restored, so the restored user still arrives as a change. It's
  kept in case the order ever changes.

### Issues Found

- **The first forced run did nothing**: WorkManager skips a periodic job that is
  forced before its period starts. The 6-hour initial delay was removed, so the
  schedule starts at once.
- **Leftover test users on the local backend**: 30 `zema-data-*@example.com`
  users came from planted-bug runs whose backend tests failed before their cleanup.
  They were deleted, and the owner's account and backup were kept.

### Not Checked / Follow-ups

- **iOS background refresh actually firing.** The simulator can trigger it with a
  debugger command (`_simulateLaunchForTaskWithIdentifier`). It wasn't tried, and
  needs a signed-in simulator.
- **The race** between opening the app and a cold background task refreshing the
  session at the same moment is not covered.
