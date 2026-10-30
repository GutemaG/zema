---
stage: test
bolt: 037-accounts-backup-restore-ui
created: 2026-10-30T12:15:33Z
---

## Test Report: accounts-backup-restore-ui (bolt 7 of 8)

### Summary

- **Tests**: app 985 (11 new) and zema_core 236 (13 new), all passing. Analyze and
  format are clean.
- **Planted bugs**: all 15 caught.
- **The emulator check of a real restore** runs end to end in bolt 038, which adds
  the screen that starts it (S26).

### Test Files

- [x] `packages/zema_core/test/backup/backup_matcher_test.dart` (13):
  - **Rule 1 (file name)**:
    - any folder and letter case, within ±2 s
    - not beyond 2 s either way
    - works without an artist
    - closest length, then lowest ID
  - **Rule 2 (tags)**:
    - case, spacing and punctuation ignored
    - Ethiopic variants, ፡ and ። ignored
    - never on the title alone (no artist, or another artist)
    - not beyond 2 s
    - a title that normalizes to nothing never matches
  - **Rule 1 comes first**, and missing tracks never match.
  - **A realistic new phone**:
    - 110 backed-up songs (Latin, Ge'ez and Oromo titles, and 10 untagged
      recordings).
    - On the new phone: other folders, some files renamed, some re-encoded
      (±1.5 s), some re-tagged, some renamed and re-titled, 3 left behind, and 40
      other songs.
    - At least 95% matched, every match right, and the ones left behind not
      matched.
  - **Speed**: 2,000 entries against 5,000 tracks (half by file name, half by tags),
    all matched, in under 2 s, building included.
- [x] `test/app/database/restore_dao_test.dart` (11, an in-memory database):
  - **Favorites**:
    - added with their dates; existing ones keep theirs
    - songs not found are reported
    - a renamed file is found by its tags
  - **Playlists**:
    - a new one is created in order, with its description and date
    - the same name in another case gets its missing songs at the end, without
      repeats, keeping the local name
  - **Lyrics**: added where none was made by hand, automatic links replaced, the
    phone's own choices kept, and "no lyrics" restored.
  - **Hidden**:
    - folders mapped to this phone's (parents included), others to main storage
    - songs hidden by match
    - songs not found reported
  - **`keepUnmatched`** gets the entries not found.
  - **An error midway changes nothing** in any table.
  - **Restoring twice** adds nothing the second time.
  - **`BackupRestorer`**: settings are applied and saved after the merge; a failed
    merge applies none.

### Acceptance Criteria Validation

- ✅ **The matcher's two rules, never title alone**: core tests.
- ✅ **The merge**:
  - favorites added
  - playlists extended or created
  - manual choices only where none exist
  - settings applied

  Covered by the database and restorer tests.
- ✅ **An error midway changes nothing**: a throwing `keepUnmatched` rolls back all
  six tables. A failed merge applies no settings.
- ✅ **2,000 against 5,000 in under 2 s**: timed test.
- ✅ **≥ 95% matched on a realistic fixture**: the new-phone test, with every match
  correct.

### Planted Bugs (15)

All caught:
- **Matcher**:
  - a 3 s tolerance
  - case-sensitive file names
  - matching on the title alone
  - no rule 2
  - matching missing tracks
  - the farthest length winning
  - tags not normalized
- **Merge**:
  - existing favorites overwritten
  - playlist songs put at the start
  - case-sensitive playlist names
  - manual choices overwritten
  - songs not found not reported
  - no transaction
  - parent folders not hidden
- **Restorer**: settings applied before the merge.

### Issues Found

- **The matcher crashed on a gap of exactly 2.001 s** (found by tests). The "none
  yet" starting value tied with the gap. Fixed by skipping anything over the
  tolerance first.
- **The hidden count was wrong** (found by tests). Drift's `insert` returns the row
  ID, not a count. Counts are now made against the existing rows.

### Not Checked / Follow-ups

- The emulator check (phone A's backup → wiped phone restore) is in bolt 038.
