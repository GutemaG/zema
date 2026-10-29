---
stage: plan
bolt: 018-cloud-lyrics-catalog-backend
created: 2026-10-29T06:03:48Z
---

## Implementation Plan: cloud-lyrics-catalog-backend (bolt 1 of 4)

### Objective

Set up a local Supabase project in `backend/` with the catalog schema as migrations, so
the database builds from scratch with one command and is covered by tests (story 001).

### Deliverables

- **`backend/supabase/`**
  - Made with `npx supabase init`, then trimmed: only the API and database matter now.
    Studio stays on for browsing; email, storage and the realtime config stay at their
    defaults.
  - Project ID: `zema`.
- **Migration `…_catalog_schema.sql`**
  - **Enums**:
    - `song_status`: draft, approved, rejected
    - `section_kind`: verse, chorus, bridge, other (the same as `SectionKind`)
    - `recording_source`: bundled, local_file, youtube, telegram
    - `report_reason`: wrong_words, wrong_timing, wrong_song, other
    - `app_role`: contributor, moderator, admin
    - `contribution_kind`: new_song, edit_lyrics, sync_timing
    - `contribution_status`: pending, approved, changes_requested, rejected
  - **`songs`**:
    - `id`: text slug, checked with `^[a-z0-9]+(-[a-z0-9]+)*$`
    - `title`, `transliteration`, `artist`, `album`
    - `status`
    - `version`: int, starts at 1
    - `created_at`, `updated_at`, `approved_at`
  - **`sections`**: (song_id, id) key, plus kind and position.
  - **`lines`**: (song_id, section_id, position) key, plus text and transliteration.
  - **`play_order`**: (song_id, position) key, plus section_id.
  - **`recordings`**:
    - `id`: slug
    - song_id, source, artist
    - `duration_ms`
    - `offset_ms`: positive means later, as in `zema_core`
  - **`sync_timings`**:
    - one per recording
    - `starts_ms int[]`, checked to be non-empty and never going backwards
  - **`reports`**:
    - id, song_id, recording_id, reason
    - `note`: at most 500 characters
    - `install_hash`, status, created_at
  - **`user_roles`**: user_id → `auth.users`, plus role.
  - **`contributions`**:
    - id, song_id, author_id, kind
    - `payload`: jsonb
    - status, review_note, reviewer_id, created_at, reviewed_at
  - **Deleting**: removing a song removes its sections, lines, play order, recordings and timings. Reports and contributions keep the song ID but become null.
  - **Version**: triggers on sections, lines, play order, recordings and timings, and on a song's own text columns, bump `songs.version` and set `updated_at`. Approving a song sets `approved_at`.
  - **Row Level Security**: on for every table, with **no policies yet**, so nothing is readable or writable through the API until bolt 019 adds the read rules. A safe default.
- **pgTAP tests** in `backend/supabase/tests/database/`:
  - All 10 tables exist, with RLS on.
  - Key constraints:
    - slug format
    - timings that go backwards are rejected
    - note length
    - deleting a song cascades to its parts
  - **Version**: editing a line bumps the version, and so does adding a recording.
  - **Approval**: approving a song sets `approved_at`.
- **`backend/README.md`**:
  - what's needed (Docker, Node)
  - `npx supabase start`, `db reset`, `test db` and `stop`
  - where to find the local URL and keys (`npx supabase status`)
  - that keys are never committed
- **`.gitignore`**: `backend/supabase/.temp`, `.branches` and `.env`.

### Dependencies

- Docker (running) and Node/npx (present). The Supabase CLI is 2.122 via `npx`.
- The first `supabase start` downloads the Docker images (about 1–2 GB).

### Technical Approach

- **Migration style**: plain SQL migrations, one file per bolt or concern, applied by
  `supabase db reset`. That is the source of truth, and nothing is changed by hand
  in Studio.
- **Version bump**: in one trigger function, `bump_song_version(song_id)`, called by
  row-level triggers. Several bumps in one transaction are fine; it only has to
  increase.
- **Contributions and roles**: the tables match what intents 005 and 006 need. Nothing
  writes them yet.

### Acceptance Criteria

- [ ] `npx supabase db reset` builds the schema with no errors
- [ ] `npx supabase test db` passes: tables, RLS on, constraints, cascades, version bumps
- [ ] The README lets someone start, reset and test from scratch
- [ ] No keys or local state are committed
