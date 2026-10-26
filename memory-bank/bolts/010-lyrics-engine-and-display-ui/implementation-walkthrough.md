---
stage: implement
bolt: 010-lyrics-engine-and-display-ui
created: 2026-10-26T14:51:32Z
---

## Implementation Walkthrough: lyrics-engine-and-display-ui (bolt 2 of 9)

### Summary

`zema_core` can now compare search text the way people type it: Ethiopic spelling variants fold together, title noise is dropped, and Ethiopic and Latin spellings meet through a consonant skeleton with a 0–1 match score. Nothing in the app uses it yet; Search does in bolt 011.

### Structure Overview

The rules are const data in one file. Two small modules apply them: normalization (one text → normalized words) and transliteration (words → consonant skeletons, and a score between a query and a target). A `SearchKey` holds both forms of a text so each song is prepared once.

### Completed Work

- [x] `packages/zema_core/lib/src/search/search_tables.dart` - row and syllable folds, Ethiopic row consonants, Latin spelling folds, vowels, accent folds, noise phrases and years
- [x] `packages/zema_core/lib/src/search/normalize.dart` - `normalizeSearchText` / `searchWords`, `foldCharacter`, Ethiopic row helpers
- [x] `packages/zema_core/lib/src/search/transliteration.dart` - `consonantSkeleton`, `SearchKey`, `matchScore`, `matchThreshold` (0.75), `isMatch`
- [x] `packages/zema_core/lib/zema_core.dart` - exports the three files

### Key Decisions

- **Letters and digits from Unicode classes** (`\p{L}`, `\p{N}` with `unicode: true`): every script's letters are kept by definition, so nothing like the old `[^a-z0-9]` can delete Ethiopic. Combining marks are removed before splitting so a decomposed "é" doesn't split a word.
- **No Unicode normalization package**: precomposed Latin accents fold through a table, and combining marks are dropped, which covers both forms.
- **Scores, not yes/no**: Search can rank exact matches above prefixes and near spellings; the 0.75 cut-off keeps "selot" → "ጸሎት" (one letter off) and drops unrelated words (0.25–0.5 in a spot check).
- **`normalizeTitle` unchanged**: rescan fingerprints keep their stored form.

### Deviations from Plan

None.

### Dependencies Added

None.

### Developer Notes

- Spot check: "ቅድስት", "ቅዱስት", "kidist", "qidist", "kiddist" → "kdst"; "እግዚአብሔር" and "egziabher" → "gzbhr"; "ሥላሴ" and "ስላሴ" normalize to the same text; "ፀሎት - Zemari Kidus | Official Video 2019 (New Mezmur) ft. Abebe" → "ጸሎት zemari kidus abebe".
- Short vowel-only Latin words have an empty skeleton and only match by text.
