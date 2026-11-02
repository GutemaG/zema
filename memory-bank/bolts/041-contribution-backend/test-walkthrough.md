---
stage: test
bolt: 041-contribution-backend
created: 2026-11-02T09:40:00Z
---

## Test Report: contribution-backend (bolt 3 of 3)

### Summary

- **Tests**: 545 pgTAP tests in 15 files, all passing. 40 are new, in
  `015_publish.test.sql`.
- **The seed tests (006, 007) pass unchanged**, so seeding is still idempotent with the
  new document keys.
- **Planted bugs**: 10, all caught.

### Test Files

- [x] `backend/supabase/tests/database/015_publish.test.sql` (40):
  - **New songs**:
    - Published as approved, with the title trimmed.
    - `get_song` serves the lyrics, the recording with its file name, and the timing.
    - It's in the song index as synced, and the contribution points at its song.
    - A taken slug gets `-2`, then `-3`; a 120-character slug is shortened to fit.
    - A YouTube recording is served with its video ID and no timing.
  - **Corrections**:
    - The title and lines are replaced, and the version goes up.
    - The same sung-line count keeps the timing; a different count removes it.
    - The recordings stay, and the play order and lines are replaced, not added to.
  - **Recordings and syncs**:
    - A recording is added with its file name and timing.
    - A sync adds a timing; a second sync replaces it.
  - **Failures**:
    - A sync made before a correction changed the line count is refused with
      `timing_count`. It stays pending, and the timing is unchanged.
    - A new song whose recording ID is taken is refused with `bad_recording`. Nothing
      is published and it stays pending.
  - **Nothing before approval**:
    - A pending or rejected song isn't served or indexed, and isn't in the catalog,
      even as a draft.
    - A recording sent back for changes isn't there.

### Acceptance Criteria Validation

- ✅ **A new song is public with its recording, timing and source; the slug is unique
  when taken**: the new-song tests.
- ✅ **A correction replaces the text, bumps the version, removes only timings that
  don't fit**: the correction tests.
- ✅ **A recording or sync is added; a sync replaces**: the recording and sync tests.
- ✅ **A failure leaves it pending and the catalog unchanged**: the failure tests.
- ✅ **Nothing readable by `anon` before approval**: the before-approval tests, run as
  `anon`.
- ✅ **The seed tests still pass**: 006 and 007.
- ✅ **The whole pgTAP suite passes**: 545 of 545.

### Planted Bugs (10, all caught)

- slug not made unique
- title not trimmed
- a correction keeps every timing
- a correction drops every timing
- no rule check on approval
- a sync doesn't replace
- `song_document` leaves out `fileName`
- `seed_song` drops `youtubeId`
- a recording drops its file name
- a taken recording ID not checked

### Issues Found

None in this bolt's code.

### Not Checked / Follow-ups

- **The app doesn't read `youtubeId` and `fileName` yet.** Bolt 042 adds them to
  `zema_core`'s `Recording`.
