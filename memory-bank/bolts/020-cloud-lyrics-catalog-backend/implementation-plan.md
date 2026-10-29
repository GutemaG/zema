---
stage: plan
bolt: 020-cloud-lyrics-catalog-backend
created: 2026-10-29T06:24:45Z
---

## Implementation Plan: cloud-lyrics-catalog-backend (bolt 3 of 4)

### Objective

Make the server search the catalog exactly like the app does: the same spelling folds,
transliteration skeletons and scoring (stories 004 and 005). The rules are generated
from `zema_core`'s tables, so the two can't drift. Parity tests compare the server's
answers with `zema_core`'s on the same inputs.

### Deliverables

- **Generator: `packages/zema_core/tool/generate_search_sql.dart`** (story 004)
  - It writes `backend/supabase/migrations/20261029020000_search_rules.sql` from
    `search_tables.dart`. The output has:
    - **Lookup tables**: `search_row_folds`, `search_syllable_folds`,
      `search_row_consonants`, `search_latin_folds` (ordered), `search_accent_folds`
      and `search_noise_phrases`.
    - **`zema_search_words(text) → text[]`**: lower-case, fold rows, syllables and
      accents, drop combining marks, split on anything that isn't a letter or digit,
      then drop noise phrases and years.
    - **`zema_skeleton(word) → text`**: row consonants, Latin folds applied per Latin
      run or per syllable, vowels dropped, repeated letters collapsed.
    - **`zema_match_score(query_words, query_skeletons, target_words,
      target_skeletons) → float`**: `matchScore` line for line. Exact, prefix (0.9),
      inside (0.8), then edit distance on skeletons. Edit distance uses
      `fuzzystrmatch.levenshtein`, which matches Dart's `_distance`.
  - It also writes a **generated parity test**, `tests/database/004_search_parity.test.sql`:
    - `zema_core`'s expected words and skeletons for about 60 inputs, taken from the 003
      normalize and transliteration tests. These include Ethiopic, accents, noise,
      years, punctuation (፡ ።), labialized rows, "gn" across syllables, digits and
      Greek.
    - Expected scores for a set of query and target pairs.
  - **Staleness check**: a Dart test in `zema_core` regenerates both files in memory
    and fails if the committed copies differ. Changing a rule table without rerunning
    the generator breaks the build.
- **Migration `…_search_index.sql`** (story 005)
  - **`search_entries`**: one per song for its title, transliteration and artist, plus
    one per distinct line (text and transliteration), holding `words` and
    `skeletons` arrays.
  - **`search_vocab`**: each distinct word with its skeleton, linked to the entries it
    appears in.
  - **Triggers** on `songs` and `lines` keep both in step.
  - **Readability**: the tables follow the songs' rules, so only approved songs are
    readable, and nobody can write them.
- **`search_songs(query text, max_results int default 20)`**, callable by `anon`
  - **Returns** `(song_id, title, transliteration, artist, score, line_text,
    line_transliteration)`:
    - one row per approved song
    - its best entry; `line_*` is null when the title entry wins
    - sorted by score (highest first), then title
    - only scores of at least 0.75
  - **Speed**: each query word is scored against the vocabulary (thousands of words),
    not every line. Matching words lead back to their entries, and each entry gets the
    mean of its best word scores. Edit distance is worked out at most once per
    distinct word, and the answer stays exact.
- **pgTAP `005_search_songs.test.sql`**
  - Fixtures: the three sample songs, a "Kidus" song in Latin and Ethiopic, and a draft
    song.
  - The 003 queries ("kidist", "ቅድስት", "ቅዱስት", "selam", "birhan" and the rest) give
    the expected songs. The expected lists come from `zema_core` and are written into
    the generated parity file.
  - A lyric line query returns the song with that line.
  - Draft songs never appear.
  - An empty or one-letter query returns nothing.
- **Timing check**: a script loads 5,000 generated songs, about 150,000 lines, into
  the local database and times `search_songs`. The target is under 200 ms; the result
  goes in the test walkthrough. It isn't run as part of `test db`.

### Technical Approach

- **Same results**: everything `search_songs` scores goes through the same three
  generated functions the parity test checks.
- **Unicode**: letters and digits of every script are kept with
  `[[:alpha:][:digit:]]` in a Unicode-aware form. If Postgres's character classes
  disagree with Dart's `\p{L}` and `\p{N}` for some input, the generator writes
  explicit code-point ranges instead. The parity test decides.
- **Extensions**: `fuzzystrmatch` (for `levenshtein`) is enabled in the
  `extensions` schema. Supabase ships it.

### Acceptance Criteria

- [ ] The generator writes the SQL rules and parity tests; a Dart test fails if they are stale
- [ ] The server's words, skeletons and scores equal `zema_core`'s on every parity input
- [ ] `search_songs` returns the same songs as `zema_core` for the 003 queries, each once, best first, with the matching line
- [ ] Only approved songs appear; `anon` can call it but can't write the search tables
- [ ] Under 200 ms with 5,000 songs on the local database (measured)
- [ ] All earlier tests still pass
