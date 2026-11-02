---
stage: plan
bolt: 041-contribution-backend
created: 2026-11-02T08:35:00Z
---

## Implementation Plan: contribution-backend (bolt 3 of 3)

### Objective

Approving a contribution publishes it into the catalog in the same transaction. A
failure leaves the contribution pending. Story: `003-publish-on-approval`.

This bolt runs in one pass with 040, at the owner's request.

### Deliverables

- **`migrations/20261102020000_publish_contributions.sql`**:
  - **`recordings` gets two columns:**
    - `youtube_id`, matching the 11-character pattern
    - `file_name`, 1–255 characters
  - **`song_document`** is replaced so recordings carry `youtubeId` and `fileName` when
    set. `get_song` returns them. Documents without them are unchanged, so seeding
    stays idempotent.
  - **`seed_song`** is replaced so it stores the two new keys.
  - **`publish_contribution(contribution)`** is replaced with the real one:
    - **It checks first:** the shared rules run again against the current catalog.
      For example, a sync whose song changed since it was submitted fails with
      `timing_count`.
    - **`new_song`:**
      - The proposed slug is made unique (`-2`, `-3`, …, kept within 120 characters).
      - The title is trimmed.
      - A recording ID already in use fails with `bad_recording`.
      - Then `seed_song(doc, 'approved')` stores it.
    - **`edit_lyrics`:**
      - The song's title, transliteration, artist and album are updated.
      - Its sections, lines and play order are replaced.
      - Each recording whose timing count no longer matches the new sung-line count
        loses its timing; the others keep theirs.
    - **`recording`:** the recording is inserted with its source reference, plus its
      timing when there is one.
    - **`sync_timing`:** the recording's timing is inserted, or replaced if it has one.
    - **It returns the song ID.** `review_contribution` stores it on the contribution,
      so a new song's contribution points at its published song.
- **`tests/database/015_publish.test.sql`**: pgTAP tests.

### Technical Approach

- **The version goes up** through 004's existing triggers on songs, sections, lines,
  recordings and timings, so phones refresh.
- **Nothing is public before approval.** Published songs are `approved`, and 004's
  read rules are unchanged.
- **All of it runs inside `review_contribution`'s transaction.** Any error rolls back
  both the publishing and the status change.

### Acceptance Criteria

- [ ] An approved new song is public through `get_song` and `song_index`, with its
  recording, timing and source reference. Its slug is unique when the title is taken.
- [ ] An approved correction replaces the text, bumps the version, and removes only
  the timings whose count no longer fits.
- [ ] An approved recording or sync is added. A sync replaces existing timings.
- [ ] A failure while publishing leaves the contribution pending and the catalog
  unchanged.
- [ ] Nothing is readable by `anon` before approval.
- [ ] Earlier seed tests still pass (seeding is idempotent).
- [ ] The whole pgTAP suite passes.
