---
stage: plan
bolt: 010-lyrics-engine-and-display-ui
created: 2026-10-26T14:29:58Z
---

## Implementation Plan: lyrics-engine-and-display-ui (bolt 2 of 9)

### Objective

Pure-Dart search text handling in `zema_core` (stories 003 and 004), so that "kidist", "ቅድስት" and "ቅዱስት" find the same song and noise like "Official Video" is ignored. No UI in this bolt; Search (bolt 011), linking (014) and lyric search (016) build on it.

### Deliverables

- `packages/zema_core/lib/src/search/search_tables.dart`: the rules as plain data, exported so intent 004 can copy them into SQL:
  - Ethiopic consonant rows that are spelling variants, each folded to one row with the same vowel order: ሐ and ኀ → ሀ, ሠ → ሰ, ዐ → አ, ፀ → ጸ
  - vowel orders that are spelling variants: ሃ → ሀ, ኣ → አ (after the row fold, so ሓ, ኃ and ዓ follow)
  - the Latin consonant(s) for each Ethiopic consonant row, for example ቀ → q, ሸ → sh, ጸ → ts, አ → nothing
  - Latin spelling folds applied to both sides: q → k, ph → f, kh/x → h, gn → ny
  - noise phrases ("official video", "official music video", "official audio", "lyric video", "lyrics", "new mezmur", "አዲስ መዝሙር", "ft", "feat", "hd") and years 1900–2099
- `packages/zema_core/lib/src/search/normalize.dart`: `normalizeSearchText`:
  - lower-case
  - fold Ethiopic variants and Latin accents (é → e)
  - turn everything that isn't a letter or digit into a space, including Ethiopic word marks ፡ ። and combining marks
  - drop noise phrases and years; collapse spaces
  - never removes Ethiopic letters
- `packages/zema_core/lib/src/search/transliteration.dart`:
  - `consonantSkeleton(word)`: Ethiopic or Latin word → Latin consonants with vowels dropped and doubled letters collapsed ("ቅድስት", "kidist", "kiddist", "qidist" → "kdst")
  - `SearchKey`: a text's normalized words and their skeletons, computed once per song or query
  - `matchScore(query, target)`: 0–1. A query word scores 1 when it is in the target or has the same skeleton, 0.9 for a skeleton prefix (typing in progress) and 1 − edit distance / length for near spellings. One- and two-letter queries match prefixes only. The score is the mean over query words; `isMatch` requires 0.75.
- Exports from `zema_core.dart`.
- Tests in `packages/zema_core/test/search/`: every fold, noise word, mixed script and empty input; a table of query/target pairs that must and must not match; ranking.

### Dependencies

- None new. Dart's `RegExp` with `unicode: true` gives letter and digit classes (`\p{L}`, `\p{N}`), so no Unicode normalization package is needed. Combining marks are removed, and precomposed Latin accents are folded through a small table.

### Technical Approach

- Ethiopic syllables sit in rows of eight code points, one per vowel order (U+1200 ሀ … U+1207 ሇ). The fold maps a code point to the same position in the canonical row; the skeleton looks up the row's consonant. Labialized rows (ቈ, ኰ, ጐ …) map to their base consonant.
- Old title code (`normalizeTitle`, used by rescan fingerprints) stays as it is. Changing it would change stored fingerprints, and fingerprints only need to be stable, not forgiving.
- Pure functions with const tables; no state, no Flutter.

### Acceptance Criteria

- [ ] ሀ/ሐ/ኀ, ሰ/ሠ, አ/ዐ, ጸ/ፀ and ሃ/ኣ fold; Ethiopic letters are never removed; no `[^a-z0-9]` style regex
- [ ] "Official Video", "Lyrics", "New Mezmur", "ft.", years and punctuation removed; Latin lower-cased with accents dropped
- [ ] "kidist", "qidist", "kiddist" match "ቅድስት" and "ቅዱስት"; "egziabher" matches "እግዚአብሔር"; "selam" matches "ሰላም"; "tselot" matches "ጸሎት"
- [ ] Unrelated words score below the threshold and below exact matches; one- or two-letter queries match prefixes only
- [ ] Rules are exported data tables
- [ ] `dart analyze` and format clean; core tests pass
