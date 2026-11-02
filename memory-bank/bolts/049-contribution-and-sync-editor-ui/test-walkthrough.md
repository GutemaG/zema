---
stage: test
bolt: 049-contribution-and-sync-editor-ui
created: 2026-11-02T20:00:00Z
---

## Test Report: contribution-and-sync-editor-ui (bolt 8 of 11)

### Summary

- **Tests**: the app has 1137 (33 new); `zema_core` has 318 (14 new).
- **Planted bugs**: 6, all caught (one only after a fix to the code, see
  Issues).
- **Emulator**: not checked in this bolt.

### Test Files

- [x] `packages/zema_core/test/contribute/corrections_test.dart`:
  - **`changedLines`**: no change, a fixed typo, a line added and one
    removed, a changed transliteration, a new block and a deleted one, and a
    play order change alone
  - **`songChanged`**: spaces and blank details don't count; an empty play
    order is the blocks in order
  - **`recordingsLosingTimings`**: a changed line keeps every timing; a
    different sung line count drops them; a timing that didn't fit before is
    dropped too; untimed recordings are never named
  - **The drafts**: a correction sends `edit_lyrics` with the song id and base
    version and passes the rules; a recording starts at S20; a sync at S21
- [x] `apps/mobile/test/features/contribute/similar_songs_test.dart`:
  - the warning shows only after the pause, and typing on starts it again
  - Add a recording goes to S20 as a recording of that song
  - Suggest a correction fills S19 (note, fields, blocks) with base version 5,
    and Next goes to review
  - Not the same song hides it; a correction never checks
  - a title filled in before is checked when S19 opens
  - offline with no index it's skipped; a song that can't be downloaded says so
  - **Fit**: 1.3× on 360 × 640, dark and light
- [x] `apps/mobile/test/features/contribute/entry_points_test.dart`:
  - **`recordingToSync`** and **`newSongDraftFor`**
  - **Search**: the title is filled in (trimmed); a guest signs in first;
    nothing without a backend
  - **No lyrics** on Now Playing: title, artist, track and the local
    recording; a guest signs in first; only Match lyrics without a backend
  - **Song detail**: the menu entries; Suggest a correction (base version 5,
    `edit_lyrics`); Link a recording; Sync this recording opens S21 with the
    track; no Sync when the recording has a timing; a guest signs in first;
    the menu fits at 1.3×, dark and light
- [x] `apps/mobile/test/features/contribute/correction_changes_test.dart`: no
  change, a typo (struck through), added and removed lines with the recording
  that loses its timing, and fit at 1.3×, dark and light.
- [x] `apps/mobile/test/helpers/memory_lyrics.dart` (new): a catalog's lyrics
  held in memory.

### Acceptance Criteria Validation

- ✅ **Similar songs after a pause; switch to a recording or a correction; it
  can be ignored.** Offline, it's skipped quietly.
- ✅ **Search with no results → S19 with the title.**
- ✅ **A track with no lyrics → S19 with title, artist and the track.**
- ✅ **Song detail → S20 for the song / S21 for the phone's recording without
  timings** (local files only).
- ✅ **Guests see C09 first** (one shared helper).
- ✅ **Suggest a correction → S19 filled with the current song.**
- 🔶 **Changed lines and recordings losing timings on S22**: the widget is done
  and tested; placing it on S22 waits for bolt 048.
- ✅ **Submit sends `edit_lyrics` with the song ID and base version** (draft
  tests).
- 🔶 **No changes → Submit disabled**: `songChanged` is ready for S22.

### Planted Bugs (6, all caught)

- timings kept when the sung line count changes
- a correction looking for similar songs
- Song detail's correction based on version 1
- Search's title not trimmed
- a synced recording offered for syncing
- the old line not struck through

### Issues Found

- **The flow opens outside the app shell**, so the index isn't refreshed
  there in tests. The tests save the index first.
- **S19 only watched the index for new songs**, so the correction guard went
  untested (the index was never loaded). It is now always watched, and the
  planted bug is caught.
- **Song detail's recordings load a moment after the song.** The tests
  settle twice before opening the menu.
