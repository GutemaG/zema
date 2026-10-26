---
stage: test
bolt: 017-lyrics-engine-and-display-ui
created: 2026-10-26T20:42:06Z
---

## Test Report: lyrics-engine-and-display-ui (bolt 9 of 9)

### Summary

- **Tests**: 825/825 passed:
  - 179 in `packages/zema_core`, up from 178
  - 646 in `apps/mobile`, up from 640
- **Coverage**:
  - `lyrics_prefs.dart`: 66/68
  - `lyrics_options_sheet.dart`: 83/84
  - `lyrics_settings_group.dart`: 37/41
  - App total: 92.5%
- **CI sequence run locally**: all checks exit 0, and the iOS simulator build compiles.
- **Planted bugs**: both were caught.
  - Making the default always win failed the offset test.
  - Ignoring the default failed the default-offset test.

### Test Files

- [x] `lyrics_prefs_test.dart`
  - Updated: Reset now means the recording has no offset of its own.
  - New:
    - no saved value means no offset of its own
    - the default steps, is saved and is clamped
    - a nudge starts from the default, and the recording's own offset then wins over a new default
- [x] `lyrics_view_test.dart`: the default applies (11 s is still line 2 with +1.0 s); −−, then the song's own 0.0 s wins; Reset returns to +1.0 s.
- [x] `settings_screen_test.dart`
  - Five sections, in order, with Lyrics.
  - The Lyrics section changes text size, transliteration and the default offset, and saves all three.
  - It fits at 1.3× text.
- [x] `packages/zema_core/test/lyrics/sync_engine_test.dart`: accuracy.
  - At 1 ms before each of 40 line starts, the previous line is current; at the start, the line itself is current.
  - This holds with offsets of 0, +0.5 and −1.5 s, and `startOf` matches.

### Intent 003 Done-When Checks

- ✅ **No "Coming soon" on Home and Search**: emulator, offline; widget tests (bolts 009, 011)
- ✅ **Highlighted within ±0.3 s of timing**:
  - The engine is exact (the accuracy test).
  - just_audio's position stream updates at least every 200 ms, so the highlight lags by at most 0.2 s.
- ✅ **"kidist", "ቅድስት", "ቅዱስት" find the same song**: core tests (bolt 010); emulator for Latin
- ✅ **Core unit tests**: sync, play order, normalization, transliteration, LRC import, matching and lyric search, 179 tests in all
- ✅ **Widget tests for Home, Search, C06, S07 and Settings at 1.3× in both themes**

### Acceptance Criteria (story 016)

- ✅ Settings has a Lyrics section with text size, transliteration and default sync offset
- ✅ Changes apply to the lyrics view and Song detail at once (shared provider; tests) and persist
- ✅ A recording's own offset wins over the default (tests)
