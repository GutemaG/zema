---
stage: plan
bolt: 039-contribution-backend
created: 2026-11-02T07:20:00Z
---

## Implementation Plan: contribution-backend (bolt 1 of 3)

### Objective

Signed-in users can submit a contribution, and resubmit one that needs changes, only
through server functions. Those functions check:

- the shared lyrics rules
- the payload's shape for each kind
- the abuse limits

Users read only their own contributions, and nobody writes the table directly. Story:
`001-submit-contributions`.

### Deliverables

- **`migrations/20261102000000_contribution_kind_recording.sql`**: adds the
  `recording` value to `contribution_kind`. It's in its own file because Postgres
  can't use a new enum value in the transaction that adds it.
- **`migrations/20261102000100_submit_contributions.sql`**:
  - **New columns on `contributions`**:
    - `base_version` (for `edit_lyrics`)
    - `submitted_at` (set on submit and resubmit; the queue orders by it in bolt 040)
    - `revision` (1 on submit, +1 on each resubmit)
    - `size_bytes`, generated, checked ≤ 262,144 (256 KB)
  - **Indexes** for the limit counts: `(author_id, status)` and
    `(author_id, created_at)`.
  - **`sung_line_count(song jsonb)`**: the number of line occurrences in the play order.
    `seed_song` keeps its own copy for now; bolt 041 can share this one.
  - **`contribution_error(kind, song_id, base_version, payload)`**: returns the first
    broken rule as a code, or null. It's not callable from the API.
  - **`submit_contribution(kind, payload, song_id default null, base_version default
    null)`**: returns the new ID.
  - **`resubmit_contribution(id, payload)`**: returns the new revision.
  - **The policy "Users read their own contributions"**, for select by `authenticated`
    with `author_id = auth.uid()`. Writes stay revoked (004's default).
- **`tests/database/013_contributions.test.sql`**: pgTAP tests.

### Payload by kind

The payload uses 004's song document shape (`{song, recordings, timings}`). Each kind
uses only part of it.

- **`new_song`**:
  - `song` is required. Its `id` is a slug the app proposes from the title; bolt 041
    makes it unique when publishing.
  - `recordings` is optional, with at most 1 entry. `timings` is optional, at most 1,
    and only with a recording.
  - `song_id` must be null.
- **`edit_lyrics`**:
  - `song_id` must be an approved song. `base_version` is required and must be ≤ the
    song's current version.
  - Only `song` is allowed. Its `id` must equal `song_id`.
- **`recording`**:
  - `song_id` must be an approved song.
  - `recordings` must have exactly 1 entry, whose `songId` is `song_id`.
  - `timings` is optional (at most 1), counted against the song's current play order.
- **`sync_timing`**:
  - `song_id` must be an approved song.
  - `timings` must have exactly 1 entry, whose `recordingId` is an existing recording
    of that song.
- **A recording in a payload**:
  - `id` is a slug (the app uses a lower-case UUID). `source` is `localFile`,
    `telegram` or `youtube` (not `bundled`).
  - `youtube` needs `youtubeId` matching `^[A-Za-z0-9_-]{11}$`, and can't have timings.
  - `localFile` and `telegram` need `fileName`, 1–255 characters.
  - `durationMs` is optional and > 0.
  - `youtubeId` and `fileName` are new keys. Bolt 041 stores them and `get_song`
    returns them.

### Rules and error codes

Each error is raised with errcode `22023` and the code as its message. These codes are
the shared list that `zema_core` mirrors in bolt 042:

- **Song**:
  - `title_required`, `title_too_long` (1–200 characters after trimming)
  - `no_sections`, `empty_section` (every line's text non-empty after trimming),
    `bad_section` (unknown kind or a duplicate ID), `too_many_lines` (> 300 written
    lines)
  - `play_order_empty`, `play_order_unknown_section`
- **Timings**:
  - `timing_count` (≠ the sung line count)
  - `timing_order` (negative, or not strictly increasing)
  - `timing_past_duration` (past `durationMs` when it's known)
  - `youtube_not_synced`
- **Recording**: `bad_recording` (bad ID, source or `fileName`), `bad_video_id`
- **Kind and song**: `missing_song`, `missing_recording`, `missing_timing`,
  `song_not_allowed`, `unknown_song` (unknown or not approved, the same answer as 004),
  `unknown_recording`, `bad_base_version`, `bad_payload` (not an object, or keys of the
  wrong type)
- **Limits**, raised with errcode `PT429`, which PostgREST turns into HTTP 429:
  - `too_many_open`: 20 contributions already `pending` or `changes_requested`
  - `too_many_today`: 30 submitted in the last 24 hours
- **Others**:
  - `payload_too_large` (errcode `54000`)
  - `not_signed_in` (`28000`)
  - `not_editable` (`22023`), for resubmitting someone else's contribution, or one
    that isn't `changes_requested`

### Dependencies

- **004**: `contributions`, `song_document()`, the read rules, and revoked write grants.
- **005**: signed-in users (`auth.uid()`) and the test-user pattern.
- **Local Supabase** in Docker (`npx supabase db reset`, `npx supabase test db`).

### Technical Approach

- The RPCs are `security definer`, with `set search_path = ''`. `execute` is revoked
  from public and anon, and granted to authenticated, as in `save_backup`.
- **Validation is one plpgsql function**, which walks the JSON in a fixed order (shape,
  then song, then recording, then timings) and returns the first broken rule. Submit
  and resubmit both call it.
- **`sync_timing` and `recording` with timings** count sung lines from the song's
  current approved document, through `song_document(song_id)`.
- **The limits** count by `author_id`:
  - Open contributions are `pending` or `changes_requested`, so a resubmit doesn't
    change the count.
  - The day limit is a rolling 24 hours on `created_at`, as for reports. A resubmit
    doesn't count.
- **Resubmit** locks the row (`for update`) and checks author and status. It replaces
  the payload, and sets `pending`, `submitted_at = now()` and `revision + 1`.
  `review_note`, `reviewer_id` and `reviewed_at` stay, so the moderator sees the
  previous comment until the next review replaces it.

### Acceptance Criteria

- [ ] A signed-in user submits each of the four kinds, and gets the ID; the row is
  `pending` with them as author.
- [ ] Every rule above is refused with its code, at least one test per code.
- [ ] Exactly 256 KB is accepted, one byte more is refused. The 21st open contribution
  and the 31st in 24 hours are refused with `PT429`.
- [ ] Resubmit works only for the author's own `changes_requested` row. The status
  goes back to `pending`, the revision goes up, and the note stays.
- [ ] Users read only their own rows, and `anon` reads none. Direct insert, update and
  delete are refused for everyone.
- [ ] A guest's `submit_contribution` is refused with `not_signed_in`.
- [ ] `npx supabase db reset` and `npx supabase test db` pass, and the 12 earlier test
  files still pass.
- [ ] Key scan clean before commit.

### Deviations from the story

- **The day limit is a rolling 24 hours**, not "today in UTC". It matches reports and
  avoids a burst at midnight.
- **"Open" counts `changes_requested` as well as `pending`**, so resubmitting can't go
  over 20.
