---
stage: test
bolt: 046-contribution-and-sync-editor-ui
created: 2026-11-02T16:40:00Z
---

## Test Report: contribution-and-sync-editor-ui (bolt 5 of 11)

### Summary

- **Tests**: app 1,099, of which 13 are new; `zema_core` 302, of which 6 are new. All
  passing. Analyze and format are clean.
- **Planted bugs**: 5, all caught.
- **Emulator**: S21 needs a signed-in draft, so it waits for the owner's sign-in. The
  audio paths it plays (a `content://` track, a `file://` copy) are the ones bolt 045
  checked on the emulator.

### Test Files

- [x] `packages/zema_core/test/contribute/sync_editing_test.dart` (6):
  - taps in order, ignored after the last line
  - a tap not after the previous line is ignored
  - undo
  - nudges stay clear of neighbours and above zero
  - redo, and where it restarts playback
  - starts fitted to the line count
- [x] `apps/mobile/test/features/contribute/sync_step_test.dart` (13):
  - **The rows**: one per occurrence (the chorus twice), untimed; the shared copy is
    loaded; play, then tap.
  - **Taps**: each times the next line at the position and is saved; once all are
    timed, Next goes to review.
  - **Undo** clears the last time.
  - **Nudges**: ±0.1 s, holding repeats, and it stops 0.1 s before the next line.
  - **Redo from here** clears from that line, seeks to 3 s before it, and plays.
  - **−5 s and the speed toggle.**
  - **Skip** sends the text only.
  - **The players**: the main player pauses; the background pauses syncing; closing
    frees the player.
  - **A library track** plays from its URI.
  - **A missing recording** says so, and goes back to S20.
  - **Changed lyrics** start the times over.
  - **Fit**: 1.3× on 360 × 640, dark and light, with a row's controls open.

### Acceptance Criteria Validation

- ✅ **The List view**: playback bar, rows in play order with time or —, the current
  line highlighted, Undo, the big Tap button, no counters.
- ✅ **A tap records the position** for the highlighted line, and the next one lights
  up. The position is read at the tap, not from the last stream value.
- ✅ **Nudge ±0.1 s without passing neighbours; Redo from here plays from 3 s before.**
- ✅ **Undo last tap.**
- ✅ **Chorus repeats are separate rows.**
- ✅ **Skip, send text only, opens review with no timings.**
- ✅ **Each tap is saved; the main player pauses.**
- ✅ **Edge cases: a tap after the last line is ignored; backgrounding pauses and
  keeps the times.**

### Planted Bugs (5, all caught)

- the main player keeps playing
- no pause in the background
- Redo plays from the line instead of 3 s before it
- Skip keeps the times
- the player isn't freed

### Issues Found

- **Loading in `initState` changed providers while building.** It now runs after the
  first frame.
- **A tooltip's long press beat hold-to-nudge.** The nudge buttons use a semantics
  label instead.
- **Held nudges read a stale start.** Edits now apply to the latest draft.
- **`libraryTracksProvider.future` hangs in widget tests.** The track is read with a
  plain query.
