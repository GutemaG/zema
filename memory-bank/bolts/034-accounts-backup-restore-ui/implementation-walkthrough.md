---
stage: implement
bolt: 034-accounts-backup-restore-ui
created: 2026-10-30T10:45:00Z
---

## Implementation Walkthrough: accounts-backup-restore-ui (bolt 4 of 8)

### Summary

- **Settings → Account & backup**:
  - For a guest, it opens C09, a sheet that says why an account is needed, with
    Sign in and Not now. Sign in opens S24, which returns to Settings.
  - A signed-in user goes to Backup & sync (S25b), which for now lists what is
    backed up.
  - Builds without sign-in don't show the row.
- **`zema_core`** defines the backup: `BackupDocument` (format 1) with
  `TrackIdentity` tracks.
- **The app's `BackupBuilder`** fills it from the database and the settings.

### Structure Overview

- **`zema_core/src/backup/`**: `track_identity.dart` and `backup_document.dart`,
  plus `BackupFormatFailure` in `failures.dart`.
- **`app/database/backup_dao.dart`**: one read of everything a backup holds.
- **`features/account/data/backup_builder.dart`**:
  - the builder
  - `storageRelativePath`
  - `backupSettings`, and its reverse `settingsFromBackup` (for bolt 037)
- **`features/account/presentation/`**: `widgets/sign_in_prompt.dart` (C09) and
  `backup_screen.dart` (S25b).

### Completed Work

- [x] `TrackIdentity`:
  - title, artist, album, duration in ms, and the file name (`fileNameOf`, the
    path's last part)
  - JSON keys `title`, `artist`, `album`, `ms`, `file`, with nulls left out
- [x] `BackupDocument`:
  - **Sections**: favorites (with the date added), playlists (name, description,
    date created, tracks in order), manual lyrics choices (song ID, or null for no
    lyrics), hidden folders and tracks, and settings as plain values.
  - **JSON**:
    - Tracks are written once in `tracks`, and the sections refer to them by
      index.
    - Unknown top-level sections are kept in `extras` and written back.
    - Unknown fields inside an entry are ignored.
    - Missing sections read as empty.
  - **Errors**:
    - A newer `format` throws `BackupFormatFailure(newerFormat: true)`.
    - Anything malformed throws `BackupFormatFailure` as well.
- [x] `BackupDao.read()`: favorites, playlists with ordered entries, manual links,
  and hidden folders and tracks, each joined to its track, in one transaction.
- [x] `BackupBuilder.build(settings)`:
  - It converts the rows to identities and dates to UTC.
  - Folders are stored relative to their storage volume.
  - Settings go in by name.
- [x] **C09**:
  - `showSignInPrompt(context, reason:)` opens a bottom sheet sized to its
    content: an icon, "Sign in to continue", the reason, Sign in (filled) and Not
    now.
  - It resolves to whether the user is signed in afterwards.
- [x] **Settings**: an Account group with Account & backup, shown when sign-in is
  available. A guest gets C09; a signed-in user gets `/backup`.
- [x] **S25b** at `AppRoutes.backup`: "What's backed up" and "Not backed up".
- [x] **Strings**: 10 new English strings.

### Key Decisions

- **One track list, referred to by index.** A song that is a favorite and sits in
  three playlists is stored once. Short keys keep the worst case (6,000 different
  tracks) under 1 MB.
- **Hidden folders relative to their volume.** The backup then holds no path from
  this phone, and `Recordings` names the same folder on the next phone.
- **Settings as a map of plain values in `zema_core`.** The core stays free of
  Flutter types, and the app owns the keys. Unknown keys and values are ignored
  when read back.
- **Back from C09's sign-in returns to Settings, not on to S25b.** That's what the
  story asks, and the restore prompt after sign-in (bolt 038) shouldn't compete
  with it.

### Deviations from Plan

- **Settings watches the signed-in user while sign-in is available.** Riverpod
  pauses providers nobody listens to, so before this change the tap waited on a
  restore that never ran.
- **`showSignInPrompt` reads the repository's current user**, not the provider. The
  provider's stream may not have delivered the new user by the time S24 pops.

### Dependencies Added

- None.

### Developer Notes

- Bolt 035 adds the backup status, Back up now, Restore and Auto backup to S25b.
- Bolt 038 adds unmatched entries to the document from the new Drift table.
