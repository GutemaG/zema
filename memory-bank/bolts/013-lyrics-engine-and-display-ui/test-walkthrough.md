---
stage: test
bolt: 013-lyrics-engine-and-display-ui
created: 2026-10-26T17:43:02Z
---

## Test Report: lyrics-engine-and-display-ui (bolt 5 of 9)

### Summary

- **Tests**: 753/753 passed:
  - 164 in `packages/zema_core`, up from 140
  - 589 in `apps/mobile`, up from 582
- **Coverage**: `lrc_import.dart` 94/96 and `lyrics_repository.dart` 12/12 (after a ranking test), missing only a `toString`; `bundled_lyrics_repository.dart` 51/54. App total 94.5%.
- **CI sequence run locally**: format check, `dart analyze`, `dart test`, `flutter analyze`, `flutter test` all exit 0. The iOS simulator build compiles (the asset folder is bundled).
- **Emulator**: the sample audio was generated and pushed; nothing in the app shows lyrics yet (bolt 015).

### Test Files

- [x] `packages/zema_core/test/lyrics/lrc_import_test.dart`:
  - time tags with 0–3 decimals and 3-digit minutes; several tags per line; time order; file order for equal times; the result always fits `SyncedLyrics`
  - ti/ar/al; title defaults to the ID; offset sign converted; a bad offset skipped; `[tr:]` on every time of a line, ignored without a line before it; other tags ignored
  - chorus detection: chorus between verses, the longest block over its parts, a song starting with its chorus, a single repeated line not a chorus, no repeat → one verse, a repeat without its `[tr:]` line still matches
  - untimed text and empty timed lines skipped with line numbers; Windows line endings; Ethiopic kept exactly; nothing timed → `LyricsFormatFailure`
  - `searchSongs`: title, transliteration and artist; ranking with ties in order; empty and unrelated queries
- [x] `apps/mobile/test/features/lyrics/data/bundled_lyrics_repository_test.dart`:
  - **the real bundled files**: three songs load, each with one recording, timing that fits, the v1/chorus/v2/chorus/chorus order, at least 10 sung lines, and a last line starting before the audio ends
  - Amharic songs carry title and line transliterations
  - search by title, Ethiopic and Latin spelling; unknown IDs
  - files read once
  - missing, untimed, ID-less and duplicate entries skipped while the rest load
  - an unreadable index → `LyricsFormatFailure`

### Acceptance Criteria Validation

Story 009: LRC import
- ✅ **`[mm:ss.xx]` tags → song, recording and timing**: tests
- ✅ **Several time tags → several occurrences**: test
- ✅ **A repeated block becomes one chorus in the play order**: tests
- ✅ **offset / ti / ar / al tags**: tests
- ✅ **Malformed lines skipped and listed; Ethiopic kept**: tests

Story 010: Bundled lyrics repository and sample songs
- ✅ **List, get and search by normalized title**: tests
- ✅ **3 placeholder songs (Amharic and Afaan Oromoo) loaded from LRC**: tests with the real assets
- ✅ **Script generates matching tagged audio to push**: run during implementation (53 s and 43 s files, pushed)
- ✅ **A malformed asset is skipped and logged; the rest load**: test

### Issues Found

- **A weak test** (found by a planted bug): reloading the files on every call passed, because the fake asset bundle cached reads itself. The fake now counts every read.
- Coverage showed song search ranking untested; a test was added.

### Notes

- **Planted bugs**: each of these makes a test fail:
  - the offset not negated
  - fractions misread
  - the shortest block winning
  - a chorus without a repeat
  - choruses compared with transliteration
  - lines not sorted by time
  - an empty timed line not reported
  - duplicates kept
  - files reloaded on every call
  - the title transliteration dropped
- No bridge in the samples (LRC has no section marks); see the implementation walkthrough.
- The sample text is placeholder Amharic and Afaan Oromoo; it needs a native speaker's review before any release.
