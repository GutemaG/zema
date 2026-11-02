---
stage: test
bolt: 047-contribution-and-sync-editor-ui
created: 2026-11-02T17:30:00Z
---

## Test Report: contribution-and-sync-editor-ui (bolt 6 of 11)

### Summary

- **Tests**: `sync_step_test.dart` now has 18 (5 new, and one changed for "Play to
  start"); `zema_core` has 1 new. The 74 lyrics tests pass unchanged after the split.
  Full-suite counts are in the construction log.
- **Planted bugs**: 4, all caught.
- **Emulator**: S21 waits for the owner's sign-in.

### Test Files

- [x] `apps/mobile/test/features/contribute/sync_step_test.dart`:
  - **Focus**:
    - the line before with ✓ time, CHORUS with the next line, then the line after
    - the area plays, then taps
    - Undo, −5 s and Pause
  - **Switching views** keeps the times, the position, playback and the same player.
  - **Focus with every line timed** goes on to review.
  - **Preview**:
    - plays from 0:00 in `LyricsLines`, and the highlight follows the times
    - Back pauses and returns
    - it needs at least one time
  - **Fit**: the List, Focus and Preview views at 1.3× on 360 × 640, dark and light.
- [x] `packages/zema_core/test/contribute/sync_editing_test.dart`: `lineAt`.
- [x] `apps/mobile/test/features/lyrics/`: unchanged and passing (74).

### Acceptance Criteria Validation

- ✅ **The Focus view**: the line before with its time, the current line large with
  its block, the next line, the big tap area, and Undo / Pause / −5 s. No counters.
- ✅ **Toggling carries the same times and position.**
- ✅ **Preview plays from the start, highlighting through C06.**
- ✅ **Fits at 1.3× on a small phone, dark and light**, for all three views.
- ✅ **Edge case: toggling mid-playback keeps playing.**

### Planted Bugs (4, all caught)

- Preview not from the start
- Preview keeps playing after Back
- the Focus tap area does nothing
- Preview highlights the first line instead of the current one

### Issues Found

- **The S21 controls took most of a small screen at 1.3× text.** The toggles are now
  icons, and Skip moved into the menu.
- **A menu item with a null value never calls `onSelected`.** It uses a string value.
- **A position event shows one frame later in tests.** The preview test pumps twice.
