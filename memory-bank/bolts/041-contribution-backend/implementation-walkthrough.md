---
stage: implement
bolt: 041-contribution-backend
created: 2026-11-02T09:10:00Z
---

## Implementation Walkthrough: contribution-backend (bolt 3 of 3)

### Summary

Approving a contribution now publishes it into the catalog inside the review's
transaction. That covers a new song, a correction, a recording, and a sync. Recordings
keep where they come from: a YouTube video ID, or a file name. Song documents and
`get_song` carry that, so other phones can match the recording later.

### Structure Overview

- **One migration** adds the two recording columns. It also replaces three functions:
  - `song_document` and `seed_song`, the same as before plus the source reference
  - the placeholder `publish_contribution` from 040
- **Publishing re-runs the shared rules first**, against the catalog as it is now.
  Then it branches by kind.

### Completed Work

- [x] `backend/supabase/migrations/20261102020000_publish_contributions.sql`:
  - **`recordings.youtube_id`** and **`recordings.file_name`**, with checks.
  - **`song_document`** adds `youtubeId` and `fileName` when they're set.
  - **`seed_song`** stores them.
  - **`publish_contribution`**:
    - **`new_song`**: a unique slug and a trimmed title, then `seed_song` stores it as
      approved.
    - **`edit_lyrics`**: the text, sections, lines and play order are replaced, and
      timings that no longer fit are removed.
    - **`recording`**: the recording is inserted, with its timing.
    - **`sync_timing`**: the timing is upserted.

### Key Decisions

- **The rules run again on approval.** A sync submitted before a correction changed
  the line count fails with `timing_count`, instead of publishing timings that don't
  fit. The moderator can request changes.
- **New songs reuse `seed_song`.** It's the tested path that writes 004's document
  format.
- **Corrections don't use `seed_song`.** It deletes a song's recordings; a correction
  must keep them, and their timings when the sung-line count is the same.
- **A taken recording ID fails** (`bad_recording`) rather than being renamed. App IDs
  are UUIDs, so this only happens when the same recording is sent twice.
- **`song_document` leaves out unset keys**, so seeded documents compare equal as
  before. The seed tests still pass.

### Deviations from Plan

None.

### Dependencies Added

None.

### Developer Notes

- The version goes up through 004's triggers. One approval can raise it by more than
  one, which is fine: phones only compare versions.
- `zema_core`'s `Recording` doesn't read `youtubeId` or `fileName` yet. Bolt 042 adds
  them, and older apps ignore unknown keys.
