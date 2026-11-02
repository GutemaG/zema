---
stage: implement
bolt: 039-contribution-backend
created: 2026-11-02T07:45:00Z
---

## Implementation Walkthrough: contribution-backend (bolt 1 of 3)

### Summary

Signed-in users can now submit contributions, and resubmit one a moderator sent back,
through two server functions. Every payload is checked against the shared rules for
its kind. The checks return a named error code, and the limits answer with HTTP 429.
Users read only their own contributions, and the table can't be written directly.

### Structure Overview

- **Two server functions**: submit and resubmit.
- **One internal raiser**: shared by both. It checks size first, then rules.
- **One internal validator**: returns the first broken rule as a code.
- **Validator helpers**, written so each can be tested alone:
  - song
  - recording
  - timing
  - sung-line count
  - JSON integer and optional-text checks
- **Limits**: counted from `contributions`, on two new indexes.
- **Reads**: a single select policy limits them to the author.

### Completed Work

- [x] `backend/supabase/migrations/20261102000000_contribution_kind_recording.sql`:
  adds the `recording` contribution kind.
- [x] `backend/supabase/migrations/20261102000100_submit_contributions.sql`:
  - **New columns on `contributions`**:
    - `base_version`
    - `submitted_at`
    - `revision`
    - `size_bytes`, generated, with a 256 KB check
  - **Indexes** for the limits.
  - **The read-own policy.**
  - **Validation helpers**: `is_json_int`, `is_optional_text`, `sung_line_count`,
    `song_payload_error`, `recording_payload_error`, `timing_payload_error`.
  - **`contribution_error` and `check_contribution`**, closed to the API.
  - **`submit_contribution` and `resubmit_contribution`**, for signed-in users only.
  - The header lists every error code with its errcode, for `zema_core` to mirror.

### Key Decisions

- **The code goes in the error message**:
  - The errcode groups the errors: `22023` for rules, `54000` for size, `PT429` for
    limits, `28000` for not signed in.
  - The message is the machine code, such as `timing_count`. The app maps it without
    parsing text.
- **`song_id` is `text`, not the `slug` domain.** A malformed ID gets `unknown_song`,
  not a domain-check error.
- **Size is checked before the rules**, so an oversized payload isn't walked. The
  generated `size_bytes` check backs it up.
- **The validators are `immutable` and pure** where they can be. Only
  `contribution_error` reads tables: the song's version and status, its existing
  recordings, and the current document for the sung-line count.
- **Resubmit** keeps the kind, song and base version from the original row, and
  replaces only the payload.

### Deviations from Plan

- **Added `field_too_long`**: transliteration, artist and album over 200 characters,
  and line text over 500. These limits weren't in the plan; without them the only
  bound on long fields was 256 KB.
- **Line transliteration** is capped at 500 characters, the same as line text.

### Dependencies Added

None.

### Developer Notes

- `sung_line_count` is the same rule `seed_song` uses: play order, or every section
  once. Bolt 041 can switch `seed_song` to it.
- Each `PT429` code becomes an HTTP 429 in PostgREST, as `submit_report` does.
- Smoke-checked in a rolled-back transaction: a new song with a recording and timings
  is accepted, and a wrong timing count is refused with `timing_count`.
