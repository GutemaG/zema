---
stage: test
bolt: 015-lyrics-engine-and-display-ui
created: 2026-10-26T19:57:47Z
---

## Test Report: lyrics-engine-and-display-ui (bolt 7 of 9)

### Summary

- **Tests**: 800/800 passed:
  - 174 in `packages/zema_core`, unchanged
  - 626 in `apps/mobile`, up from 604
- **Coverage**:
  - `lyrics_view.dart`: 157/158
  - `lyrics_options_sheet.dart`: 82/84
  - `lyrics_prefs.dart`: 51/53
  - `track_lyrics.dart`: 24/27 (the untested lines are the "timing doesn't fit" log)
  - `now_playing_screen.dart`: 161/163
  - App total: 92.4%, excluding generated code
- **CI sequence run locally**: format check, `dart analyze`, `dart test`, `flutter analyze` and `flutter test` all exit 0. The iOS simulator build compiles.
- **Planted bugs**: all 4 were caught:
  - the user offset ignored
  - the 3 s pause ignored
  - seeking without the offset
  - no ±10 s clamp
- **Bug found by the tests and fixed**: after a manual scroll while paused, auto-scroll never resumed. The scroll waited for a frame that never came, so `_followSoon` now asks for a frame.
- **Cosmetic fix**: lyrics now fade out over the top 48 px, so they no longer run into the artist name and the options button.

### Test Files

- [x] `test/features/lyrics/application/lyrics_prefs_test.dart`: 8 tests
  - display defaults
  - the transliteration setting is saved
  - text size steps of 0.1 without drift, with the 0.8 and 1.6 limits
  - saved values load and out-of-range ones are clamped
  - offsets saved per recording in 0.5 s steps
  - offsets clamped to ±10 s
  - reset forgets the saved offset
  - `formatOffset`
- [x] `test/features/lyrics/presentation/lyrics_view_test.dart`: 14 widget tests
  - **Preview**: the panel under the artwork follows the current line and opens lyrics mode.
  - **Highlighting**: the current line uses `primaryText` and bold, past lines `faint` and later ones `muted`; 3 chorus labels show, the current line is marked selected for screen readers, and each repeat is highlighted on its own.
  - **Seeking**: tapping a line seeks to its start, and seeking includes the offset.
  - **Scrolling**:
    - The view keeps the current line at about 0.33 of its height, going forwards and backwards.
    - A manual scroll pauses following for 3 s.
  - **Options**:
    - The offset moves the highlight at once and is saved; reset restores it.
    - A+ to 140% grows the text and keeps the current line in place.
    - Transliteration shows when on.
  - **Track change**: the next track shows its own lyrics.
  - **Plain lyrics**: no highlight, no seeking, and no offset control.
  - **Unlinked track**: shows No lyrics, and Match lyrics opens the picker.
  - **1.3× text** in light and dark, with the options sheet and transliteration on: no overflow.

### Test Helpers

- `pumpZemaApp` takes a `lyricsRepository`, and `lyricsOverrides(repository:)`.

### Acceptance Criteria

**Story 012: lyrics view**
- ✅ Current line highlighted, past lines faint, choruses marked (tests and emulator)
- ✅ Tapping a line seeks to it (tests and emulator)
- ✅ Plain lyrics show without highlight (test)
- ✅ No lyrics state with Match lyrics (test)
- ✅ Transliteration toggle (test)
- ✅ 1.3× text in light and dark (tests)
- ✅ A track change switches the lyrics (test)

**Story 013: auto-scroll and offset**
- ✅ Scrolls to keep the current line in view (tests and emulator)
- ✅ A manual scroll pauses following, which resumes after 3 s (test)
- ✅ The offset moves in 0.5 s steps, shows at once, is saved per recording, and is clamped to ±10 s (tests)
- ✅ A−/A+ keeps the current line in view (test)
