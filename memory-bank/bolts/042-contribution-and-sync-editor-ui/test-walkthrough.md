---
stage: test
bolt: 042-contribution-and-sync-editor-ui
created: 2026-11-02T11:30:00Z
---

## Test Report: contribution-and-sync-editor-ui (bolt 1 of 11)

### Summary

- **Tests**:
  - `zema_core`: 283, of which 47 are new.
  - `zema_data`: 62, of which 4 are new and run against the local backend.
  - App: 1,024, of which 6 are new.
  - pgTAP: 546, of which 1 is new.
  - All passing. Analyze and format are clean.
- **Planted bugs**: 17. 16 were caught on the first run; the 17th was caught after
  two test links were added.
- **Two unrelated problems were found and fixed** (see Issues Found).

### Test Files

- [x] `packages/zema_core/test/contribute/contribution_test.dart` (11):
  - Payloads for all four kinds, through JSON text and back. A new song with lyrics
    only has no recordings or timings.
  - A payload missing what its kind needs is refused.
  - `Recording` keeps `youtubeId` and `fileName`, and they count for equality. Without
    them the JSON is as before.
  - Wire names of kinds, statuses and decisions; which decisions need a note.
  - A queued correction knows when it was based on an older version.
- [x] `packages/zema_core/test/contribute/contribution_rules_test.dart` (21):
  - **The sung-line count.**
  - **Every kind valid**: new song (with and without a recording, YouTube), correction,
    recording and sync.
  - **The song**:
    - title blank, 200 (also padded) vs 201
    - field and line limits
    - no sections, an empty section, a blank line, duplicate section IDs
    - 300 vs 301 lines
    - empty and unknown play order
    - several errors listed once, in order
  - **The recording**: eight bad ones (bundled, no file name, blank name, a name over
    255, zero duration, another song, a bad ID, a long artist); an unknown duration is
    fine; YouTube without a valid ID.
  - **Timings**: count, ties and negatives, past the duration (and any start with no
    duration), YouTube, another recording.
  - **Kinds**:
    - a timing with no recording
    - a correction's ID and base version
    - recording and sync counted against the current song, or left to the backend
      without it
    - a sync for another song's recording
  - **Codes**: a failure reads its code, and an unknown one is null. **Parity**: the
    migrations' codes equal `ContributionError`'s, no more and no fewer.
  - **Slug and video ID checks.**
- [x] `packages/zema_core/test/contribute/contribute_text_test.dart` (15):
  - **Paste-split**:
    - blank lines split sections
    - a repeated section becomes the chorus, sung each time
    - Windows line endings, spaces, and lines of only spaces
    - empty input gives nothing
    - the result passes the song rules
  - **YouTube**: 14 link forms read, and 10 non-links refused, including other sites
    with YouTube-like paths.
  - **Slugs**:
    - the transliteration is used when given; Ethiopic gives its consonants
    - Latin text loses punctuation and accents
    - long titles stop at a word within 120 characters
    - nothing usable gives "song", and every result is a valid slug
  - **Recording IDs**: 100 are unique, version-4 UUIDs, and valid slugs.
- [x] `packages/zema_data/test/contribution_backend_test.dart` (4, local backend):
  - **The full round trip**:
    - submit, and the author sees it pending, with the payload exact
    - the moderator's queue has the author's name; the kind filter works
    - request changes, and the author sees the note
    - resubmit to revision 2, then reject
  - **An approved new song** is published. The catalog serves its recording's file
    name and its timing, and the author's contribution points at the song.
  - **Refusals reach the app with their code**: a broken rule, not a moderator (403),
    a second review (409), a missing note, and the 21st open contribution (429).
  - **Signed out**: an `AuthFailure`, and nothing is sent.
- [x] `apps/mobile/test/helpers/fake_contributions_test.dart` (6): the fake's round
  trip, rules and limit, syncs against the catalog, review rules, resubmit rules,
  signed out, and a set failure.
- [x] `backend/supabase/tests/database/014_review.test.sql` (+1): `service_role` runs
  `set_moderator`.
- [x] `apps/mobile/test/features/home/presentation/home_screen_test.dart`: its tracks
  are now dated yesterday (see Issues Found).

### Acceptance Criteria Validation

- ✅ **All four kinds round-trip in 004's format**: the payload tests, and the backend
  round trip (exact payload from `mine`).
- ✅ **Each rule code tested; the Dart codes equal the server's**: the rules tests, and
  the parity test.
- ✅ **Paste-split, YouTube and slugs**, including Windows line endings and a chorus
  pasted three times: the text tests.
- ✅ **The repository works end to end; errors map to typed failures**: the 4 backend
  tests.
- ✅ **The fake follows the same rules**: the fake's tests.
- ✅ **Analyze and format clean; all tests pass**: see Summary.

### Planted Bugs (17)

- **Caught**:
  - timings allowed to tie
  - the title not trimmed
  - 301 lines allowed
  - an unknown play-order section allowed
  - the video ID not checked
  - a correction's song ID not checked
  - no chorus found
  - spacing kept when comparing pasted sections
  - shorts links not read
  - Ethiopic words dropped from slugs
  - slugs over 120 characters
  - the UUID not version 4
  - the timing not sent
  - `fileName` ignored for equality
  - codes not mapped to `ContributionFailure`
  - the fake's open limit at 21
- **Missed first, then caught**: **any website accepted as YouTube.** None of the
  "not a video" examples had a YouTube-like path on another site. Two such links were
  added.

### Issues Found

- **Bolt 040's `set_moderator` didn't work with the service key.** It reads
  `auth.users`, which `service_role` can't read; the pgTAP tests had called it as the
  owner. It's now `security definer` (new migration), with a test as `service_role`.
  The script was unaffected, because it connects as the owner.
- **A date bomb in the home screen test (from 002).**
  - Its tracks were dated 2026-10-01, and Recently added covers 30 days, so from
    2026-11-02 the Recently added test failed.
  - The tracks are now dated yesterday, through a new optional `dateAdded` on
    `scannedAudio`.
  - The two "Continue listening" failures in one full run came from the file being
    edited while that run was going. A clean run passes all 1,024.

### Not Checked / Follow-ups

- Nothing in the app uses the repository yet. Bolt 043 adds the Contribute tab and
  drafts, and bolt 048 the submitting.
