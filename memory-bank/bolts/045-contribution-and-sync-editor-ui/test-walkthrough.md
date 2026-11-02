---
stage: test
bolt: 045-contribution-and-sync-editor-ui
created: 2026-11-02T15:50:00Z
---

## Test Report: contribution-and-sync-editor-ui (bolt 4 of 11)

### Summary

- **Tests**: app 1,086, of which 17 are new; `zema_core` 296, of which 3 are new
  (plus a draft field check). All passing. Analyze and format are clean.
- **Planted bugs**: 6, all caught. The Skip test was strengthened after one slipped
  through.
- **Emulator**: real `SEND audio/*` intents, from a cold start and while running.
  - The file is copied into `files/shared_audio` at full size, and C09 opens.
  - Not now deletes the copy.
  - S20 itself waits for the owner's sign-in.

### Test Files

- [x] `packages/zema_core/test/contribute/duration_text_test.dart` (3): reads m:ss and
  h:mm:ss, refuses bad input and zero, and round-trips.
- [x] `contribution_draft_test.dart`: the new fields round-trip.
- [x] `apps/mobile/test/features/contribute/recording_step_test.dart` (17):
  - **A song on the phone**:
    - search, pick, file name and length kept, artist filled in, Next to sync
    - the opening track is marked in the picker
  - **YouTube**:
    - a playlist link is refused
    - a link is looked up: thumbnail, title, the channel as the artist, Next to review
      with the explanation
    - offline: the id is kept, the title is typed, and a bad length keeps Next off
  - **Skip** clears even a chosen recording; a correction has no Skip.
  - **Next with lyrics to fix** goes back to them.
  - **Back and the step strip** go back.
  - **Shared audio**:
    - a cold-start share opens S20 with the file
    - a share while running does too
    - a guest: C09, and Not now deletes the copy
    - a guest who signs in goes on
    - without a backend: a message, and the copy is deleted
    - deleting the draft deletes the copy, and so does signing out
  - **Fit**: 1.3× on 360 × 640, dark and light.

### Acceptance Criteria Validation

- ✅ **Local file**: searchable, duration and file name kept, the opening track marked.
- ✅ **YouTube**: id parsed, oEmbed title and thumbnail, length typed; offline keeps
  the id and lets the title be typed.
- ✅ **YouTube skips S21 with an explanation**.
- ✅ **Skip for a new song**.
- ✅ **Artist filled in** from the track's artist.
- ✅ **Edge case: a playlist or channel link** is an error on the field.
- ✅ **Share to Zema**: copied, S20 opens with it, C09 first. Checked on the emulator up
  to C09.
- ✅ **Source `telegram`, with the file name and duration**.
- ⚠️ **The copy is removed with the draft** (✅). Removal after approval or rejection
  comes in bolt 050.
- ⏭ **It plays in S21**: S21 comes in bolt 046.
- ✅ **Edge case: a non-audio file is not offered** (the filter is `audio/*`).
- ✅ **Edge case: a cold start opens S20** (in the tests; on the emulator up to C09).

### Planted Bugs (6, all caught)

- YouTube not skipping sync
- artist not filled in
- any link accepted
- Skip keeps the recording
- deleting a draft keeps the file
- a guest not asked to sign in

### Issues Found

- **The Back and Skip row overflowed at 1.3× text.** It's an `OverflowBar` now.
- **Tests that wait for real file work** use `runAsync`.
