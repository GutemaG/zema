---
stage: test
bolt: 039-contribution-backend
created: 2026-11-02T08:20:00Z
---

## Test Report: contribution-backend (bolt 1 of 3)

### Summary

- **Tests**: 463 pgTAP tests in 13 files, all passing (`npx supabase test db` after
  `npx supabase db reset`). 89 are new, in `013_contributions.test.sql`; 1 is new in
  `002_read_policies.test.sql`.
- **Planted bugs**: 16, all caught.

### Test Files

- [x] `backend/supabase/tests/database/013_contributions.test.sql` (89):
  - **Sung lines**: counted per play-order entry, or every section once without a play
    order.
  - **Valid payloads**: all four kinds pass, including a new song with a local or
    YouTube recording, and a correction based on the current version.
  - **Every rule code**, at least once:
    - **Shape**: `bad_payload` (not an object, two recordings, ID not a slug, title not
      a string, a start that isn't a whole number).
    - **Song**: blank and missing title; 200 vs 201 characters; `field_too_long`
      (artist, line); `no_sections`; `empty_section` (no lines, blank line);
      `bad_section` (kind, duplicate ID); 300 vs 301 lines; empty or missing play order;
      unknown section in the play order.
    - **Recording**: `bad_recording` (bundled, no file name, zero duration, another
      song, bad ID, an ID already used); `bad_video_id` (short, missing).
    - **Timings**: `timing_count`; `timing_order` (a tie, a negative start);
      `timing_past_duration`, and any start allowed with no duration;
      `youtube_not_synced` (new song and sync); `unknown_recording`.
    - **Kinds and songs**:
      - `missing_song`, `missing_recording`, `missing_timing`, `song_not_allowed`
      - `unknown_song` (unknown, draft, malformed ID)
      - `bad_base_version` (missing, in the future, on a new song)
      - a correction whose song ID differs
      - a sync counted against the current song
  - **Submitting**:
    - All four kinds are pending, by their author, at revision 1. The base version is
      kept.
    - A rule error is raised as `22023` with its code.
    - Exactly 256 KB is accepted and recorded; one byte more is refused with `54000`.
  - **Writes and guests**:
    - Direct insert, update and delete are refused (`42501`).
    - No user gives `not_signed_in` (`28000`).
    - `anon` can't call submit and reads nothing.
  - **Other users**: see none of another user's contributions, only their own.
  - **Limits**:
    - The 21st open contribution is refused (`PT429`), and `changes_requested` counts.
    - Reviewed ones no longer count.
    - The 30th in 24 hours is accepted and the 31st refused. Older ones don't count.
  - **Resubmit**:
    - Another user can't resubmit, and a rule error changes nothing.
    - The author gets revision 2: pending, with the new payload and time, and the note
      kept.
    - A pending contribution or an unknown ID gets `not_editable`.
- [x] `backend/supabase/tests/database/002_read_policies.test.sql`:
  - 004's "no policy opens contributions" became "no policy opens reports".
  - A new test checks contributions have exactly one policy, `SELECT {authenticated}`.
  - The catalog policy count leaves contributions out, as it already did for profiles
    and backups.

### Acceptance Criteria Validation

- ✅ **A signed-in user submits each kind and gets the ID, pending, as author**: the
  Submitting tests.
- ✅ **Every rule refused with its code**: the rule tests (all codes in the migration
  header).
- ✅ **256 KB exactly accepted; the 21st open and the 31st in 24 hours refused**: the
  size and limit tests.
- ✅ **Resubmit only the author's `changes_requested`; pending, revision +1, note
  kept**: the resubmit tests.
- ✅ **Own rows only; anon none; no direct writes**: the read and write tests, and
  002's policy check.
- ✅ **A guest is refused with `not_signed_in`**: the guest tests.
- ✅ **Reset and test pass, and the 12 earlier files still pass**: 463 of 463.

### Planted Bugs (16, all caught)

- timings allowed to tie
- open limit at 21
- a 48-hour day window
- everyone reads every contribution
- resubmit by any author
- resubmit in any status
- the size limit one byte higher
- a future base version allowed
- draft songs editable
- YouTube timings allowed
- the revision not increased
- the play order ignored when counting lines
- 301 lines allowed
- a guest can submit
- a recording ID reused
- a 201-character title allowed

### Issues Found

- **004's policy test (002) assumed contributions would never have a policy.**
  Updated, as 005 did for profiles and backups.
- **The test with four rows at the same `created_at` depended on row order.** It now
  compares them as a set.

### Not Checked / Follow-ups

- **The HTTP mapping through PostgREST** (429 for `PT429`, and the message reaching the
  app) is checked in bolt 042's `zema_data` integration tests, with a real signed-in
  session.
