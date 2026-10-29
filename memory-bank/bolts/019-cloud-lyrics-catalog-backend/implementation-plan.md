---
stage: plan
bolt: 019-cloud-lyrics-catalog-backend
created: 2026-10-29T06:17:46Z
---

## Implementation Plan: cloud-lyrics-catalog-backend (bolt 2 of 4)

### Objective

Let anyone read approved songs, and nothing else (story 002). Let listeners report wrong
lyrics without signing in, through one checked and rate-limited function (story 003).

### Deliverables

- **Migration `…_read_policies.sql`** (story 002)
  - **Read rules** for the `anon` and `authenticated` roles:
    - `songs`: rows where `status = 'approved'`.
    - `sections`, `lines`, `play_order`, `recordings`: rows whose song is approved, checked with `exists (…)`.
    - `sync_timings`: rows whose recording's song is approved.
    - `reports`, `contributions`, `user_roles`: no rules, so nothing is readable.
  - **No write rules at all**: inserts, updates and deletes fail for `anon` and `authenticated`.
  - **Grants**: table write privileges are revoked from `anon` and `authenticated` too, so writes are blocked twice: once by the missing rules and once by the grants.
  - **Indexes** that keep the "is the song approved" checks fast: `songs (status)`, plus the existing `song_id` keys.
- **Migration `…_submit_report.sql`** (story 003)
  - The function is `submit_report(song_id, recording_id, reason, note, install_id)`. It returns the new report's ID.
  - It runs with the owner's rights and a fixed `search_path`; only `anon` and `authenticated` may call it.
  - **Checks**, each with a clear error code:
    - The song exists and is approved, and the recording belongs to it. Otherwise it fails with `22023`, as invalid input. It doesn't say whether the song exists.
    - The reason is one of the four values, enforced by the enum.
    - The note is at most 500 characters after trimming; an empty note is stored as null.
    - The install ID is 8–64 characters.
  - **Privacy**: it stores `install_hash = sha256(install_id)`, never the raw ID.
  - **Rate limit**:
    - If the same hash has 5 or more reports in the last 24 hours, it fails with **`PT429`**, which PostgREST turns into HTTP 429.
    - It counts the last 24 hours, not the calendar day.
  - The report table itself stays closed to everyone.
- **pgTAP `002_read_policies.test.sql`** (running as `anon` with `set local role anon`, then as `authenticated`):
  - **What `anon` sees**:
    - approved songs and all their parts
    - none of a draft or rejected song's rows, in every table
    - nothing in reports, contributions or user roles
  - **Writes**: an insert, update or delete as `anon` on each table fails or affects 0 rows.
  - **Status change**: a song moved from approved back to draft disappears at once.
- **pgTAP `003_submit_report.test.sql`**:
  - A valid report is stored, with the hash and not the raw ID.
  - The 6th report from one install within 24 hours fails with `PT429`; a different install is unaffected.
  - Reports older than 24 hours don't count.
  - Each of these is refused:
    - an unknown song or a draft song
    - a recording from another song
    - a note over 500 characters
    - a missing or short install ID
  - `anon` can call the function but still can't read reports.
- **Check through the API**: with the anon key:
  - `GET /rest/v1/songs` lists only approved rows
  - `POST /rest/v1/rpc/submit_report` works
  - the 6th call returns HTTP 429

### Technical Approach

- **Hashing**: `pgcrypto` (`extensions.digest`), which Supabase installs by default.
- **Rate limit**: counted against the existing `(install_hash, created_at)` index. A
  concurrency gap of one extra report under a race is acceptable for spam control.
- **Hiding unapproved songs**: unknown and unapproved songs give the same error, so the
  function doesn't reveal draft songs.

### Acceptance Criteria

- [ ] `anon` reads only approved songs and their parts; nothing else; no direct writes (pgTAP)
- [ ] `submit_report` stores a hashed, validated report; the 6th in 24 h is refused with `PT429` (pgTAP + API)
- [ ] All earlier tests still pass after `db reset`
