---
stage: test
bolt: 035-accounts-backup-restore-ui
created: 2026-10-30T11:41:30Z
---

## Test Report: accounts-backup-restore-ui (bolt 5 of 8)

### Summary

- **Tests**: app 956 (28 new), zema_data 58 (6 new), zema_core 223, all passing.
  Analyze and format are clean.
- **On the Android emulator, against the local backend**:
  - Back up now uploaded the phone's favorite and settings. The row on the server
    matched, with no path.
  - A backup from "another phone" (its time moved back on the server) brought up
    the warning. Replace overwrote it.
  - Offline showed the error, and the row was unchanged.
- **Planted bugs**: 16, all caught. Two got through the first run; a new controller
  test catches them.

### Test Files

- [x] `packages/zema_data/test/account_backend_test.dart` (+6, the local backend):
  - none at first, then save and read back exactly (extras included)
  - a save replaces the last one
  - users can't read each other's backups
  - a newer format says so
  - offline gives `NetworkFailure`
  - a guest gets `AuthFailure`
- [x] `test/features/account/backup_service_test.dart` (12):
  - **Uploads**:
    - an upload records the time
    - settings as they are now
    - this phone's second backup replaces the first without asking
  - **Another phone's backup**: not replaced without `replace`. With it, it's
    replaced and then counts as this phone's.
  - **Failures**:
    - Offline: the cloud and the last time are unchanged, and the error is kept.
    - A server error is recorded, and the next success clears it.
  - **Unchanged library**:
    - `skipUnchanged` skips an unchanged library.
    - Without it, the backup uploads anyway.
  - **The hash** ignores only the time the backup was made.
  - **Status store**: defaults, a round trip per user, and unreadable data.
- [x] `test/features/account/backup_controller_test.dart` (3):
  - a second Back up now while one runs is ignored
  - a guest has no status
  - delete account forgets the status, and sign-out keeps it
- [x] `test/features/account/backup_flow_test.dart` (13, the full app):
  - **The Backup group**: Never, Back up now, and Auto backup on, with the notes.
  - **Back up now**:
    - It uploads, then shows the time and "Backed up".
    - A spinner shows while it runs, and extra taps are ignored.
  - **Failures**: offline and server errors each show their message and error
    line.
  - **Another phone's backup**:
    - The warning names its date, and Cancel keeps it.
    - Replace uploads, and the next backup doesn't ask.
  - **Auto backup**: turning it off is saved.
  - **Guest and Profile**:
    - A guest sees only the notes.
    - Profile's link appears only when signed in.
  - **Fit**: at 1.3× text with the error line, in dark and light.

### Acceptance Criteria Validation

- ✅ **Last backup time or Never, the last error, Auto backup, Back up now**: flow
  tests and emulator. The Restore row comes in bolt 038, with S26.
- ✅ **Online: uploaded, and the time updates**: flow tests and emulator.
- ✅ **Offline or failing: a message, cloud unchanged**: flow and service tests,
  and the emulator with Wi-Fi and data off.
- ✅ **Another phone's cloud backup: a warning first**: flow and service tests, and
  the emulator.
- ✅ **On the emulator, the server row matches the phone**:
  - The row held format 1, 511 bytes and one track: "Amlak", Zerfe Kebede,
    75,050 ms, `02 Amlak.mp3`.
  - That track was the one favorite, and the settings were "Night Vigil" and
    system theme.
  - No `/storage` path was included.

### Planted Bugs (16)

- **Caught in the first run (14)**:
  - replace ignored
  - never asking
  - `syncedAt` not saved
  - the error not cleared
  - offline recorded as failed
  - the status not written
  - `skipUnchanged` ignored
  - the hash including the time
  - Auto backup off by default
  - Cancel replacing
  - the wrong offline message
  - the error line hidden
  - Profile's link shown to guests
  - `fetch` dropping the time
- **Missed, then caught after `backup_controller_test.dart` (2)**:
  - the running guard removed (the screen also disables the row)
  - the status kept on delete

### Issues Found

- None in the app. The two planted-bug gaps are closed.

### Not Checked / Follow-ups

- **The iOS simulator**: planned in bolt 036.
- **During a manual Back up now, the "another phone" error line shows behind the
  warning dialog.** It's accurate after Cancel.
