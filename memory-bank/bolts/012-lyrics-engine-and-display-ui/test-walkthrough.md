---
stage: test
bolt: 012-lyrics-engine-and-display-ui
created: 2026-10-26T17:33:48Z
---

## Test Report: lyrics-engine-and-display-ui (bolt 4 of 9)

### Summary

- **Tests**: 722/722 passed:
  - 140 in `packages/zema_core`, up from 101
  - 582 in `apps/mobile`, unchanged
- **Coverage**: the lyrics files are covered except `toString` and two `hashCode` getters (debug-only); every JSON check, branch and failure is covered.
- **CI sequence run locally**: format check, `dart analyze`, `dart test`, `flutter analyze`, `flutter test` all exit 0.
- **Emulator**: not needed; nothing in the app uses this code yet (bolt 015).

### Test Files

- [x] `packages/zema_core/test/lyrics/lyrics_models_test.dart`:
  - song, recording and timing survive a JSON round trip through a string
  - optional fields left out and defaulted
  - times as whole milliseconds; Ethiopic text kept exactly
  - 11 malformed inputs each give `LyricsFormatFailure`
  - value equality and hash codes
- [x] `packages/zema_core/test/lyrics/play_order_test.dart` - a chorus written once and sung three times (repeat counts 0, 1, 2); indexes, section, line and section starts; a bridge between choruses; empty sections; missing section IDs skipped and reported; no play order = written order; no sections
- [x] `packages/zema_core/test/lyrics/sync_engine_test.dart`:
  - before the first line, during each line, after the last
  - 0.3 s either side of every boundary
  - offsets of ±0.5 and ±1 s, including pushing the first line before 0 and the last past the end
  - seeks in both directions
  - lines starting together; no lines; backwards starts rejected
  - `startOf` with offsets lands on that line and never before 0
  - `SyncedLyrics.of` pairs starts with sung lines; too few, too many or backwards starts rejected

### Acceptance Criteria Validation

Story 007: Lyrics models and play order
- ✅ **Immutable models with JSON round trip**: tests
- ✅ **Repeated chorus expands to occurrences with section, line and repeat**: tests
- ✅ **Bridge, empty sections, missing sections reported**: tests
- ✅ **No play order → written order**: test

Story 008: Sync engine
- ✅ **Current and next occurrence from position and offset**: tests
- ✅ **Before the first line: none current, first next**: test
- ✅ **Seeks forwards and backwards**: test
- ✅ **Boundaries ±0.3 s and offsets ±0.5 / ±1 s**: tests
- ✅ **After the last line it stays current; timing out of order rejected**: tests

### Issues Found

None in the code. Coverage showed that a wrong-type optional text field wasn't tested; a case was added.

### Notes

- **Planted bugs**: each of these makes a test fail:
  - `<` instead of `<=` at a boundary
  - the offset sign flipped
  - backwards starts allowed
  - too many starts allowed
  - seeking before 0
  - a next line past the end
  - repeats not counted
  - missing sections not reported
  - no written-order default
  - transliteration not saved
  - unknown section kinds accepted
