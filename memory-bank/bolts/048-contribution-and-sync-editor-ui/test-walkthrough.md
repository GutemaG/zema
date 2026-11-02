---
stage: test
bolt: 048-contribution-and-sync-editor-ui
created: 2026-11-02T19:40:00Z
---

## Test Report: contribution-and-sync-editor-ui (bolt 7 of 11)

### Summary

- **Tests**: app 1146 (all pass), `zema_core` 304, `zema_data` 37 passed and 25
  skipped. The backend tests were skipped because the local Supabase wasn't
  running.
- **New**: `review_step_test.dart` 19, `own_copies_test.dart` 5,
  `own_copies_dao_test.dart` 4, 4 in `lyrics_view_test.dart`, 1 in
  `profile_controller_test.dart`, 1 migration test, 1 in `zema_core`.
- **Planted bugs**: 6, all caught.
- **Emulator**: not checked in this bolt. The owner checks S22 at merge.

### Test Files

- [x] `apps/mobile/test/features/contribute/review_step_test.dart`:
  - S22 shows the song, the lyrics in play order (the chorus labelled each
    time it is sung), the recording and Synced
  - Text only, YouTube — not synced, and no recording
  - each Edit goes to its step; Timings of a YouTube video goes to the
    recording
  - **Submit**:
    - sends one contribution, keeps the own copy, deletes the draft, and
      returns to S05 with the message
    - keeps Zema's copy of a shared file
    - broken lyrics are caught on the phone (the repository isn't called)
    - offline, server error, too many open (20), too many today (30), signed
      out: the draft is kept, the message names the problem, and the next try
      works
    - progress while sending, and a second tap sends nothing
  - **Fit**: 1.3× on 360 × 640, dark and light, with a limit message shown
- [x] `test/features/contribute/own_copies_test.dart`: approved (with and
  without a returned song id, with no track), rejected, and pending /
  changes requested / unknown copies left alone. Shared files are real temp
  files.
- [x] `test/app/database/own_copies_dao_test.dart`: round trip, order,
  replace, remove, clear, and a copy that can't be read is left out.
- [x] `test/features/lyrics/presentation/lyrics_view_test.dart`: the own copy
  shows on its track with its own timings and Pending review; removing it
  brings back the catalog song. Another track doesn't show it. The chip fits
  at 1.3× on 360 × 640, dark and light.
- [x] `test/features/account/profile_controller_test.dart`: sign-out clears
  own copies and their files.
- [x] `test/app/database/`: `schema_test` (version 9, fourteen tables) and the
  v8 → v9 migration.
- [x] `packages/zema_core/test/contribute/contribution_rules_test.dart`: the
  limits match the backend migration.

### Acceptance Criteria Validation

- ✅ **S22 shows the song, lyrics in play order, recording and sync status,
  each with Edit.**
- ✅ **Submit runs the rules again and sends one contribution; success shows a
  message.** There is no My contributions link yet (story 012).
- ✅ **Offline or a server error keeps the draft, names the problem, and
  Submit can be tried again.**
- ✅ **A pending contribution linked to a track shows on this phone marked
  Pending review.**
- ✅ **Approval / rejection**: `OwnCopyReconciler` switches the track to the
  catalog song, or removes the copy. Bolt 050 calls it.
- ✅ **Edge case: a limit names its number, and the draft is kept.**

### Planted Bugs (6, all caught)

- Submit deletes Zema's copy of the shared file
- Submit skips the rules on the phone
- no guard against a second Submit
- Timings' Edit for a YouTube recording goes to the sync step
- `trackLyricsProvider` ignores the own copy
- the reconciler links the track on rejection instead of approval

### Issues Found

- **`find.bySemanticsLabel` couldn't find Edit.** The `Semantics` wrapper
  needed `container: true`.
- **The bottom card isn't built at 1.3× on a small phone** because the list
  builds lazily. The fit test scrolls to it with `scrollUntilVisible`.
