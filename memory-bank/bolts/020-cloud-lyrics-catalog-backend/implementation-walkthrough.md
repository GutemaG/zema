---
stage: implement
bolt: 020-cloud-lyrics-catalog-backend
created: 2026-10-29T07:38:39Z
---

## Implementation Walkthrough: cloud-lyrics-catalog-backend (bolt 3 of 4)

### Summary

The server searches approved songs by title, transliteration, artist and lyric line.
- **Same answers as the app**: its rules are generated from `zema_core`, and 169
  generated parity checks confirm it agrees with the app.
- **Speed**: 16–210 ms on 5,000 songs (155,000 lines) for queries of 2 or more
  characters.

### Files

- **`packages/zema_core/tool/search_sql.dart`**, with **`generate_search_sql.dart`** as its entry point
  - **`searchRulesSql()`** writes `migrations/20261029020000_search_rules.sql`:
    - **Character folds**: every single-character fold, Ethiopic and accents, as one `translate()`, computed with `foldCharacter` itself.
    - **Consonants**: `search_syllable_consonants`, each syllable's consonant already through the Latin folds.
    - **`zema_fold_latin`**: nested `replace()` calls, in order.
    - **`zema_search_words`**:
      - Combining marks are dropped, and text splits at anything that isn't a letter or digit.
      - Both use **exact code-point ranges** computed from Dart's `\p{M}` and `\p{L}\p{N}` over all of Unicode. Postgres's own classes differ, for example on combining marks.
      - Noise phrases and years are dropped, as in `_dropNoise`.
    - **`zema_skeleton`**: per-run Latin folds, consonant lookup, vowels dropped without resetting the previous letter, as Dart does. It runs as `security definer`, because the consonant table isn't readable by `anon`.
    - **Scoring**: `zema_word_score` and `zema_match_score` as inlinable SQL (`fuzzystrmatch.levenshtein`); `zema_match_threshold`.
  - **`parityTestSql()`** writes `tests/database/004_search_parity.test.sql` with 169 checks:
    - words and skeletons for 66 texts (Ethiopic, folds, noise, years, punctuation, accents and combining marks, digits, Greek, Arabic digits, ½)
    - scores for 20 query and target pairs
    - 19 full searches over 6 songs and a draft
  - **`expectedSearch`** defines the server's search in `zema_core` terms:
    - a song's score is the better of its title entry and its best distinct line
    - at least 0.75
    - best first, then by ID
    - the line is returned only when it beats the title
- **`test/search/search_sql_test.dart`**: fails if either generated file is stale, and spot-checks the expectations.
- **`migrations/20261029020100_search_index.sql`**
  - **Tables**:
    - `search_entries`: a title entry and one per line, keyed to the line and deleted with it.
    - `search_vocab`: each word and its skeleton.
    - `search_entry_words`: which entries contain which word.
    - RLS is on with no policies, so none are readable through the API (checked: `[]`).
  - **Triggers** on `songs` (title, transliteration, artist) and `lines` keep the entries up to date: about 0.3 ms per line.
  - **`search_songs(query, max_results default 20)`** is `security definer`, callable by `anon` and `authenticated`. It runs in steps, each computed once (`materialized`):
    1. Score each query word against the vocabulary.
    2. Keep only word scores of at least `0.75·n − (n−1)`. A line can't reach the threshold with a weaker word, so this changes no result.
    3. Follow those words to their entries, and score each entry as `matchScore` does.
    4. Rank: the best entry per song (the title wins ties, then the earliest line), then the top results.
    5. Fetch the matching lines.
- **`bench/search_bench.sql`**: 5,000 synthetic songs, 30 lines each, words from a pool of 20,000 made-up Ethiopic words, in a transaction that is rolled back. It takes about 30 seconds.
- **`backend/README.md`**: Search section and `bench/`.
- **`001_catalog_schema.test.sql`**: the expected tables now include the four search tables.

### Performance Work

Measured on the 5,000-song catalog: 19,061 vocabulary words, 155,000 entries, about 800,000 word links.

1. **First version: 0.5 to 70 seconds per search.**
   - Of about 19,000 catalog words, 5,488 score above zero against "kidist", but only 26 can matter.
   - The weak ones pulled in 216,000 links instead of 992.
   - Fix: prune by `0.75·n − (n−1)`, which is exact, and score the vocabulary once.
2. **Then 0.3 to 6 seconds.**
   - The final step re-read `songs` once per candidate, and the entry aggregation was re-run once per song (5,000 times), because of bad row estimates.
   - Fix: carry the song details through, materialize the entry scores, and filter them at the threshold.
3. **A spike** of 2–9 seconds right after loading turned out to be automatic statistics collection still running (timestamps checked). Afterwards:

| Query | Time (fresh connection, as `anon`) |
|-------|------------------------------------|
| egziabher | 16 ms |
| ኾቢ, kidist, ዙገ ሂጨ, selam bet | 79–89 ms |
| bench artist 7 | 182 ms |
| ጻዑ | 209 ms |
| k, ሀ (one letter) | about 315 ms |

- **One-letter queries**: they really do match thousands of words by prefix. The app sends server searches only from 2 characters (bolt 025).
- **Synthetic data is a worst case**: random Ethiopic words pack skeletons much more densely than real lyrics do.
- **Indexing** wasn't slow. The first benchmark's 8.5-minute load came from an unindexed word pool in the benchmark script itself, which is now fixed.

### Checked Through the API (anon key)

- `rpc/search_songs` with "ቅዱስት" returns "ቅድስት ማርያም" (score 1).
- A search for "ድንግል" returns the same song with its matching line.
- The draft song never appears.
- `GET /rest/v1/search_vocab` returns `[]`.
