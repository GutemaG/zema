---
stage: test
bolt: 038-accounts-backup-restore-ui
created: 2026-10-30T12:58:04Z
---

## Test Report: accounts-backup-restore-ui (bolt 8 of 8)

### Summary

- **Tests**: app 1,018 (33 new), zema_core 236 and zema_data 58, all passing.
  Analyze and format are clean.
- **Planted bugs**: 15. Two were fixed and run again (a wrong anchor, and a gap
  closed with a new test). All 15 are now caught.
- **The intent's end-to-end check on the emulator was not completed.**
  - Phone A's library was set up and backed up, and the app's data wiped.
  - After sign-in, S26 opened as designed.
  - The owner then tapped the emulator themselves and replaced the cloud backup
    from the wiped phone. They asked to skip the check for now.
  - Phone A's database was saved before the wipe, for a later run.

### Test Files

- [x] `test/app/database/zema/migration_test.dart` (+1): v6 → v7 keeps tracks and
  favorites, and starts with no kept entries. The generated simple migrations now
  run up to v7.
- [x] `test/app/database/schema_test.dart`: version 7, with twelve tables.
- [x] `test/features/account/unmatched_test.dart` (11):
  - **The DAO**:
    - every kind kept exactly
    - adding twice keeps one of each
    - `replaceAll` and `clear`
  - **The next backup**:
    - kept favorites, choices and hidden songs are added
    - playlist entries go back to their place, or the end
    - entries of a deleted playlist are left out
    - favorites the library already has aren't added twice
  - **`retryUnmatched`**:
    - nothing is added while the songs are missing
    - once they appear, the favorite, playlist entry and lyrics choice are added
      and no longer kept, and the others stay
    - entries of a deleted playlist are dropped
    - kept entries keep their original positions
    - a restore keeps the entries not found
  - **Cleared**:
    - on sign-out and on delete account
    - not when delete fails
- [x] `test/features/account/restore_flow_test.dart` (15, the full app):
  - **S26**:
    - It shows the date, "2 favorites, 1 playlist, settings", Restore and Start
      fresh.
    - **Restore**:
      - The summary: 1 favorite, 2 playlist songs, 1 choice, and 1 song not found
        (with its artist).
      - The database and settings were restored, and one entry is kept.
      - `syncedAt` is set, and Done closes S26.
    - **Start fresh** changes nothing locally or in the cloud.
    - **Before the first scan**: "Finding the songs on this phone…", then the
      restore.
    - **Other states**:
      - no backup
      - offline, then Try again
      - a newer format ("update the app", no Try again)
  - **After sign-in**:
    - A backup this phone hasn't seen opens S26 in S24's place, and Start fresh
      returns to Settings.
    - This phone's own backup isn't offered again.
    - With no backup, or offline, it returns to Settings.
  - **Entry points and rescans**:
    - S25b → Restore from backup opens S26.
    - A rescan that finds a missing song adds it and empties the kept list.
  - **Fit**: S26 and its summary at 1.3× text on a small phone, in dark and light.
- [x] `test/features/account/profile_controller_test.dart`: now with an in-memory
  database, which sign-out clears.

### Acceptance Criteria Validation

- ✅ **After sign-in with a cloud backup, S26 shows the date, counts and settings**:
  flow tests. On the emulator, S26 opened right after sign-in (`fetch` at
  15:44:31).
- ✅ **Restore merges with progress, then the summary and songs not found**: flow
  tests.
- ✅ **Start fresh changes nothing; the cloud backup stays**: flow tests.
- ✅ **S25b → Restore opens S26**: flow test. Also seen on the emulator (the
  owner's taps).
- ✅ **Songs not found are saved (Drift v7) and included in the next backup**:
  unmatched and flow tests.
- ✅ **A rescan that finds them adds them and removes them from the list**:
  unmatched and flow tests.
- ✅ **Sign-out or delete clears them**: unmatched tests.
- ✅ **Migration v6 → v7 keeps the data**: migration test.
- ❌ **Intent check: phone A's backup restored on a wiped phone gives the same
  data**: not completed on the emulator (see Summary).
  - Covered by flow tests.
  - Phone A's snapshot holds 3 favorites, a 3-song playlist, a manual lyrics
    choice, a hidden song and Gapless off. It's saved for a later run.

### Planted Bugs (15)

- **Caught**:
  - songs not found not kept
  - the retry keeping everything
  - entries of deleted playlists kept
  - no retry after a scan
  - no wait for the first scan
  - S26 never offered
  - kept favorites not backed up
  - kept playlist entries put at the end
  - not cleared on sign-out
  - the DAO keeping duplicates
  - a newer format shown as failed
  - Start fresh restoring (caught by a hang)
  - S25b's row missing
- **Fixed and run again**:
  - **`syncedAt` not set**: the anchor didn't match the formatted code. Caught on
    the second run.
  - **The offer ignoring `syncedAt`**: missed. Caught after the "own backup isn't
    offered again" test was added.

### Issues Found

- **The "Signed in as" message covered S26's buttons** (found by tests). S24 now
  skips it when S26 opens.
- **The emulator check replaced the owner's cloud backup with an empty one.** The
  replace warning showed, and it was confirmed by hand.
  - Possible improvement: warn more strongly when this phone's library is empty
    and the cloud backup isn't.
- **Debug logging (level ALL) prints Supabase request headers, including the
  public anon key, to logcat.** Only in debug builds, and it's the local backend's
  public key. Consider lowering Supabase's log level.

### Not Checked / Follow-ups

- **The intent's end-to-end restore on the emulator**: back up phone A, wipe,
  restore, and compare with the saved snapshot.
- **The owner's cloud backup** is now the empty one from the wiped phone.
