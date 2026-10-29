---
stage: test
bolt: 018-cloud-lyrics-catalog-backend
created: 2026-10-29T06:16:29Z
---

## Test Report: cloud-lyrics-catalog-backend (bolt 1 of 4)

### Summary

- **Tests**: 28/28 pgTAP checks pass (`npx supabase test db`) after a fresh `npx supabase db reset`.
- **Planted bugs**: 6/6 caught; each was planted in the migration and checked with a reset and a test run:
  - timings allowed to go backwards
  - the trigger that bumps the version on line edits removed
  - approval not stamping `approved_at`
  - recordings no longer deleted with their song (6 checks failed)
  - RLS off on `reports`
  - the guard against a double version bump removed
- **Gap closed**: the double-bump planted bug survived at first. Nothing tested an update that changes a song's text and sets its version at the same time, as the seed script will. A new check covers it.
- **API check**: as anonymous, `GET /rest/v1/songs` returns `[]` and `POST` is refused with `42501`.
- **Dart**: no Dart code changed in this bolt; the app and core suites are unaffected.

### Test File

- [x] `backend/supabase/tests/database/001_catalog_schema.test.sql`
  - **Structure**:
    - exactly the 9 expected tables
    - RLS on for every table
    - no policies yet
  - **Constraints**:
    - slug format
    - blank title
    - timings that go backwards, are empty or are negative are rejected; equal starts are allowed
    - note length
    - play order naming a missing section
    - a zero duration
  - **Versions**:
    - bumped when a line is edited, a recording is added, timings are added or the play order changes
    - an album edit bumps by exactly 1
    - an explicit version set together with a text change is kept as given
    - approving doesn't bump
    - `approved_at` is set on approval and when a song is inserted as approved
    - a new song starts at version 1
  - **Cascades**: deleting a song removes its sections, lines, play order, recordings and timings; reports stay, with their references set to null.

### Acceptance Criteria (story 001)

- ✅ `supabase start` and `db reset` build the database from migrations with no errors
- ✅ The schema has the expected tables and key constraints
- ✅ A song's version increases when its sections or timings change
- ✅ `supabase test db` passes with a schema test
