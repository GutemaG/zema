---
stage: test
bolt: 011-lyrics-engine-and-display-ui
created: 2026-10-26T15:28:09Z
---

## Test Report: lyrics-engine-and-display-ui (bolt 3 of 9)

### Summary

- **Tests**: 683/683 passed:
  - 582 in `apps/mobile`, up from 553
  - 101 in `packages/zema_core`, unchanged
- **Coverage**: 94.5% of lines in `apps/mobile/lib/` excluding generated code (4764/5041), up from 94.3%. The new Search files are at 100%, except `search_screen.dart` (148/150: the loading spinner before the library has loaded).
- **CI sequence run locally**: format check, `flutter analyze`, `flutter test`, `dart analyze`, `dart test` all exit 0. The iOS simulator build compiles.
- **Emulator**: checked during implementation with the same code (see Notes).

### Test Files

- [x] `apps/mobile/test/features/search/application/library_search_test.dart`:
  - Ethiopic titles from Latin spellings and variants; noise ignored
  - songs by title, artists by name, albums by name and artist; unknown artists and albums not found by a name
  - text containing the query before same-consonant words (amlak / መላክ, both ways); better scores, then library order
  - empty and noise-only queries
  - 1,000 songs: each keystroke of "kidus" under 100 ms
- [x] `apps/mobile/test/features/search/application/recent_searches_test.dart` - empty or saved at start; newest first, trimmed, saved; the same search written differently (ፀሎት / ጸሎት, case) replaces the old one; blanks and noise ignored; 10 newest kept; remove and clear
- [x] `apps/mobile/test/features/search/presentation/search_screen_test.dart`:
  - hint before typing; "kidist" and "tselot" find the Ethiopic titles while typing; grouped results
  - chips filter; See all selects the chip; All shows the top 4
  - a song plays with the song results as the queue and has the song menu
  - an artist and an album open under `/search` (checked by path) without building Library; Back returns to the query and results
  - no results state; hidden songs not found; permission flow
  - recent searches: saved by the search key and by opening a result, not by typing; tapping one searches again; remove; Clear all
  - 1.3× on a 320 × 640 phone in light and dark with a long Ethiopic recent search
- [x] `apps/mobile/test/app/app_shell_test.dart` - "Coming soon" and scroll tests moved to Contribute

### Acceptance Criteria Validation

Story 005: Search screen
- ✅ **Results while typing, grouped Songs / Artists / Albums, with normalization and transliteration**: tests; emulator
- ✅ **Scope chips**: tests
- ✅ **Song plays with song results as the queue; song menu; artist and album pages open**: tests; emulator (Back returns to the results)
- ✅ **C07 no-results state**: test
- ✅ **< 100 ms per keystroke on 1,000 songs**: test

Story 006: Recent searches
- ✅ **Saved on open or submit; newest first, max 10, no duplicates by normalized form**: tests
- ✅ **Listed with remove and Clear all when the field is empty**: tests; emulator
- ✅ **Kept across restarts**: unit test (read from shared preferences at start)
- ✅ **Hint when there are none**: test; emulator

### Issues Found

- **A weak test** (found by a planted bug): opening an album at the Library path from Search still passed, because the test only checked that the Library screen wasn't built. The album and artist tests now check the page's own path under `/search`.
- **Test data, not code**: "kidist" also found songs named "Kidus", since ቅዱስ and ቅድስት are near spellings; the exact match comes first. The six-song test series was renamed so each test checks one thing.

### Notes

- **Planted bugs**: each of these makes a test fail:
  - the text tiebreak removed
  - recent duplicates kept
  - no 10-search limit
  - songs also matched by artist
  - All showing every result
  - albums opened at the Library path
  - opening a song not saving the search
- **Emulator** (implement stage, same code):
  - "amlak" finds Amlak
  - "bulk artist 1" lists Artists and Albums with See all
  - an album opens with the Search tab selected, and Back returns to the results
  - the search is saved after opening a result
  - the Ethiopic example in the hint renders
- Contribute is now the only tab that says "Coming soon" (intent 006).
