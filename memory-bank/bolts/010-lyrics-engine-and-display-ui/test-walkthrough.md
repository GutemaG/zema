---
stage: test
bolt: 010-lyrics-engine-and-display-ui
created: 2026-10-26T14:54:44Z
---

## Test Report: lyrics-engine-and-display-ui (bolt 2 of 9)

### Summary

- **Tests**: 654/654 passed:
  - 101 in `packages/zema_core`, up from 67
  - 553 in `apps/mobile`, unchanged
- **Coverage**: the three new search files are at 100% (98/98 lines).
- **CI sequence run locally**: format check, `dart analyze`, `dart test`, `flutter analyze`, `flutter test` all exit 0.
- **Emulator**: not needed; nothing in the app uses this code yet (Search, bolt 011).

### Test Files

- [x] `packages/zema_core/test/search/normalize_test.dart`:
  - each fold, with every vowel order of the row: ሐ/ኀ → ሀ, ሠ → ሰ, ዐ → አ, ፀ → ጸ; ሃ/ሓ/ኃ → ሀ, ኣ/ዓ → አ; other letters unchanged
  - Latin lower-cased and accents dropped; decomposed accents and the Ethiopic gemination mark removed without splitting words
  - punctuation, ፡ ። ፣ and spacing become one space
  - noise phrases removed, their parts kept when alone; years 1900–2099 removed, other numbers kept; Ethiopic numerals and other scripts kept; mixed scripts; empty and noise-only input
  - the tables: folds keep the consonant, noise phrases are normalized, rows start on a multiple of eight
- [x] `packages/zema_core/test/search/transliteration_test.dart`:
  - skeletons: "ቅድስት", "ቅዱስት", "kidist", "qidist", "kiddist" → "kdst"; "እግዚአብሔር"/"egziabher"; "ሰላም"; "ጸሎት"/"ፀሎት"/"tselot"; Latin folds (ph, x, kh, gn); labialized rows; vowels and repeats; digits and other scripts
  - a table of 22 query/target pairs that must match and 13 that must not
  - ranking: exact 1, typing 0.9, inside a word 0.8, near spellings lower; one- and two-letter words match starts only; mean over query words; empty query and target
  - the known limit (below), written as a test
  - 1,000 titles scored in under 50 ms

### Acceptance Criteria Validation

Story 003: Ethiopic search normalization
- ✅ **Variant letters fold to one form**: tests
- ✅ **Noise words, years and punctuation removed; Ethiopic never removed**: tests
- ✅ **Latin lower-cased, diacritics dropped**: tests
- ✅ **Rules are exported data tables; no `[^a-z0-9]` style regex**: tables in `search_tables.dart`; a planted `[^a-z0-9]` makes tests fail
- ✅ **Every fold, noise word, mixed-script and empty input covered**: tests

Story 004: Transliteration matching
- ✅ **Rule table maps syllables to Latin consonant skeletons**: tests
- ✅ **Latin queries drop vowels; q/k, doubled letters fold**: tests
- ✅ **"kidist"/"qidist"/"kiddist" ↔ "ቅድስት"/"ቅዱስት", "egziabher" ↔ "እግዚአብሔር", "selam" ↔ "ሰላም"**: tests
- ✅ **Unrelated words rank below exact matches and below the threshold**: tests
- ✅ **Table of query/target pairs**: tests

### Issues Found

- **Latin folds crossed Ethiopic syllables** (found by a test): "gn → ny" ran after Ethiopic had become Latin, so ገ + ኘ ("g" + "ny") lost its "g". Latin folds now apply to a Latin run, or to one syllable's consonant, on its own.
- **Known limit, kept**: dropping vowels lets loose spellings meet, so words with the same consonants meet too. "amlak" (አምላክ) matches "malak" (መላክ) fully, and the start of "ምልክት" at 0.9. Search can list exact text matches first; checking vowels against the Ethiopic vowel order is possible later if this shows up with real titles.

### Notes

- **Planted bugs**: each of these makes a test fail:
  - the ሠ fold removed
  - the ሃ fold removed
  - the old `[^a-z0-9]` regex
  - noise kept
  - combining marks kept
  - repeated letters not collapsed
  - fuzzy matching for one- and two-letter words
  - threshold lowered to 0.5
  - Latin folds off
- Unknown Ethiopic letters (outside the table) now pass through the skeleton instead of disappearing.
