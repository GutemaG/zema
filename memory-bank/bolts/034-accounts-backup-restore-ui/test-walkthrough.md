---
stage: test
bolt: 034-accounts-backup-restore-ui
created: 2026-10-30T11:26:44Z
---

## Test Report: accounts-backup-restore-ui (bolt 4 of 8)

### Summary

- **Tests**: app 928 (19 new) and zema_core 223 (14 new), all passing.
  `flutter analyze` and `dart analyze` are clean, and `dart format` changes nothing.
- **On the Android emulator**, against the local backend with the owner's Google
  account:
  - Signed in, Settings → Account & backup opened S25b.
  - As a guest it opened C09. Not now closed it; Sign in opened S24, then came back
    to Settings signed in, and the row then opened S25b.
- **Planted bugs**: all 15 caught. Two mutants were faulty the first time and were
  fixed and run again.

### Test Files

- [x] `packages/zema_core/test/backup/backup_document_test.dart` (14):
  - **TrackIdentity**:
    - Made from a track: tags, duration, and only the file name.
    - Nulls stay null and are left out of the JSON.
    - `fileNameOf`.
  - **BackupDocument**:
    - It is format 1.
    - Encode then decode gives the same document, also when empty.
    - Tracks are written once and referred to by index.
    - Dates are in UTC.
    - Unknown sections are kept; unknown fields are ignored; missing sections are
      empty.
    - A newer format sets `newerFormat`.
    - Nine malformed inputs each fail as not newer.
    - 1,000 favorites + 50 × 100 different songs stay under 1 MB.
- [x] `test/features/account/backup_builder_test.dart` (8, an in-memory database
  filled through the real DAOs):
  - **Contents**: every section is filled from the database and settings; only
    manual choices are included, "no lyrics" among them.
  - **Left out**:
    - No storage path, folder name or content URI is included.
    - No history and no automatic links.
  - **Edge cases**:
    - An empty library.
    - Following the phone's language isn't saved.
    - A round trip.
  - **`storageRelativePath`**: emulated and SD-card volumes, `/sdcard`, and other
    paths kept whole.
  - **`settingsFromBackup`**:
    - It reads `backupSettings` back.
    - Unknown or invalid values keep the current ones.
- [x] `test/features/account/sign_in_prompt_flow_test.dart` (11, the full app):
  - **Account & backup row**:
    - Hidden without sign-in.
    - A guest gets C09 with the reason, Sign in and Not now.
  - **Closing C09**: Not now, or tapping outside, changes nothing (no picker, still
    a guest).
  - **Signing in from C09**:
    - Sign in leads to S24, then Settings signed in, and then the row opens S25b.
    - Back from S24 returns to Settings as a guest.
  - **Signed in**: the row opens S25b directly.
  - **`showSignInPrompt`'s result**: false after Not now, true after a sign-in.
  - **Fit**: C09 at 1.3× text on a 360 × 640 phone, in dark and light.
  - **FR-9**: as a guest, nothing asks for sign-in through the following, and the
    picker is never opened:
    - every tab
    - every Library tab
    - playing a song
    - in Now Playing: favorite, lyrics, artwork, next and pause
    - a search

### Acceptance Criteria Validation

- ✅ **Guest → C09 with why, Sign in, Not now**: flow test and emulator.
- ✅ **Not now closes with no change**: flow test and emulator.
- ✅ **Sign in → S24 → back where the guest was**: flow test, and on the emulator it
  returned to Settings.
- ✅ **No sign-in prompt from player, library, search or lyrics**: the FR-9 flow
  test.
- ✅ **Signed in → S25b**: flow test and emulator.
- ✅ **No sign-in → the row is hidden**: flow test.
- ✅ **`BackupDocument` format 1 with every section, as `TrackIdentity`**: core
  tests.
- ✅ **Round trip; unknown sections kept and fields ignored**: core tests.
- ✅ **A newer format gives a clear error**: `BackupFormatFailure.newerFormat`.
  Bolt 038 shows the message.
- ✅ **Under 1 MB for 1,000 + 50 × 100**: core test, worst case (all songs
  different).
- ✅ **Built from Drift and preferences, with no paths but file names, no audio and
  no history**: builder tests.
- ✅ **A track with no artist keeps null**: core test.

### Planted Bugs (15)

All caught:
- Not now signs in
- the row shown without sign-in
- a signed-in user getting C09
- the prompt's result always false
- automatic links backed up
- playlist order reversed
- the full folder path kept
- a favorite's date not in UTC
- gapless not restored
- the identity dropping the artist
- the file name being the whole path
- extras dropped
- a newer format accepted
- tracks not deduplicated
- a playlist's description lost

Notes:
- Two were caught by the test hanging (the sheet waits) rather than by a failed
  check: "Not now signs in" and "signed-in gets C09".
- Two mutants were faulty the first time (one changed nothing, one had a wrong
  anchor). They were fixed and run again.

### Issues Found

- **Account & backup waited forever on the first tap after a cold start** (found
  by tests). Riverpod pauses providers nobody listens to, so the session restore
  never ran. Settings now watches the signed-in user.
- **`showSignInPrompt` could say "not signed in" right after a sign-in** (found by
  tests). It now reads the repository's current user.
- **C09's Not now was cut off at 1.3× text.** The sheet is now sized to its content.
- **Local backend, not Zema** (on the emulator): Google sign-in timed out after 10
  seconds.
  - The Supabase auth container couldn't reach `www.googleapis.com`, Google's key
    server.
  - Restarting the container fixed it.
  - If sign-in times out locally, check this first.

### Not Checked / Follow-ups

- The iOS simulator: planned in bolt 036.
