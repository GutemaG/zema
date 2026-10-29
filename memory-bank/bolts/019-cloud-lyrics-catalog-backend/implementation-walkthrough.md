---
stage: implement
bolt: 019-cloud-lyrics-catalog-backend
created: 2026-10-29T06:19:45Z
---

## Implementation Walkthrough: cloud-lyrics-catalog-backend (bolt 2 of 4)

### Summary

- Anyone can now read approved songs and their parts, and nothing else.
- No one can write through the API, except reports, which go through
  `submit_report`. That function checks its input, hashes the install ID and limits
  each install to 5 reports in any 24 hours.

### Files

- **`migrations/20261029010000_read_policies.sql`**
  - `songs_status_idx`
  - `is_song_approved(slug)`, a stable SQL helper
  - **Six SELECT policies** for `anon` and `authenticated`:
    - songs, where the status is approved
    - sections, lines, play_order and recordings, through `is_song_approved`
    - sync_timings, through its recording
  - **Grants**: INSERT, UPDATE, DELETE and TRUNCATE are revoked from `anon` and `authenticated` on all tables, and on future tables through default privileges. Writes fail with `42501` before RLS is even checked.
- **`migrations/20261029010100_submit_report.sql`**
  - **Signature**: `submit_report(song_id, reason, install_id, recording_id default null, note default null)`. Optional arguments come last, so the order differs from the plan; the API uses named arguments anyway.
  - **Runs as**: `security definer` with `search_path = ''`. EXECUTE is revoked from PUBLIC and granted to `anon` and `authenticated`.
  - **Checks**, each failing with `22023`:
    - install ID 8–64 characters
    - song approved (unknown and draft songs give the same message)
    - recording belongs to the song
    - trimmed note at most 500 characters; a blank note is stored as null
  - **Storage**: `encode(extensions.digest(install_id, 'sha256'), 'hex')`.
  - **Rate limit**: 5 or more reports with that hash in the last 24 hours fails with `PT429`, which becomes HTTP 429.
- **Tests**
  - `001_catalog_schema.test.sql`: the "no policies yet" check is now "every policy is read-only".
  - `002_read_policies.test.sql` (31 checks):
    - **Reads**: as `anon`, each table shows only the approved song's rows; reports, contributions and roles are empty.
    - **Writes**: 11 writes are refused with `42501`.
    - **Signed in**: `authenticated` behaves the same and can't give itself a role.
    - **Status changes**: moving a song between draft and approved takes effect at once.
    - **Policy counts**: six read policies, none on the private tables.
  - `003_submit_report.test.sql` (17 checks):
    - storing, trimming and hashing
    - a blank note becomes null
    - the five ways input is refused
    - the 6th report refused with `PT429`
    - another install unaffected
    - reports older than 24 hours no longer counted
    - PUBLIC can't execute the function

### Checked Through the API (anon key)

- `GET /rest/v1/songs` returns only the approved song.
- `POST /rest/v1/rpc/submit_report`:
  - Reports 1–5 return 200, and the 6th returns **429** `{"code":"PT429","message":"Too many reports today"}`.
  - A draft song gets **400** "Unknown song".
- `GET /rest/v1/reports` returns `[]`.
- The database was reset afterwards.
