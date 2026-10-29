---
stage: test
bolt: 020-cloud-lyrics-catalog-backend
created: 2026-10-29T08:06:13Z
---

## Test Report: cloud-lyrics-catalog-backend (bolt 3 of 4)

### Summary

- **pgTAP**: 260/260 checks pass after a fresh `db reset`:
  - 28 schema
  - 31 read rules
  - 17 reports
  - **170 generated parity checks**
  - **14 search index checks** (new)
- **Dart**: `zema_core` 182/182, including 3 tests that fail if the generated SQL is stale. Analyze and format are clean.
- **Planted bugs**: 10/10 caught. Each was planted in a migration and checked with `db reset` + `test db`.
  - **Generated rules** (a test fails if they're edited by hand, and pgTAP catches these too):
    - q→k fold dropped (2 failed)
    - vowels reset the "previous letter" (1)
    - years kept (4)
    - prefix score 0.9 → 0.8 (3)
    - short words allowed fuzzy matches (2)
    - combining marks kept (19)
  - **`search_songs`**:
    - lines win ties over titles (10)
    - draft songs searchable (6)
    - stale entries kept after an edit (29)
    - pruning by the threshold alone instead of `t·n − (n−1)`, explained below
- **Gap closed**: the over-pruning bug survived at first.
  - No parity search matched a song through a weak word.
  - I used `zema_core` to find one: "selam lezik", where "lezik" scores 0.67 against "lezih" and the average is 0.83.
  - It's now in the generated parity searches and catches the bug.
- **Speed**: measured in the implement stage on 5,000 songs and 155,000 lines.
  - 16–210 ms for queries of 2 or more characters; about 315 ms for one letter.
  - The app will send server searches from 2 characters.

### Test Files

- [x] `004_search_parity.test.sql`, generated (170 checks):
  - words and skeletons of 66 texts
  - 20 scores
  - 20 full searches, compared with `zema_core`'s `expectedSearch`
- [x] `005_search_index.test.sql`, hand-written (14 checks):
  - **Edits**:
    - an edited line matches its new text, not its old
    - a deleted line is gone from search
    - a renamed title is searchable
  - **Visibility**: a draft song isn't found.
  - **Limits**: 20 results by default; `max_results` limits them; a negative limit gives none.
  - **Deleting**: a deleted song leaves no entries.
  - **Access**: `anon` can search but can't read or write the search tables.
- [x] `001_catalog_schema.test.sql`: the four search tables are expected.
- [x] `packages/zema_core/test/search/search_sql_test.dart`: the generated files are up to date; spot-checks the expectations.

### Acceptance Criteria

**Story 004: search rules to SQL**
- ✅ The generator writes the folding tables and the word, skeleton and score functions
- ✅ The functions return `zema_core`'s output on the 003 inputs (parity)
- ✅ Changing the rule tables without regenerating fails a Dart test

**Story 005: server search**
- ✅ Title, transliteration, artist or line matches; best first, each song once, with the matching line
- ✅ The 003 queries return the same songs as `zema_core`
- ✅ Under 200 ms on 5,000 songs for queries of 2 or more characters, with 3 of 8 measured queries between 180 and 210 ms. One-letter queries take about 315 ms, and the app won't send them.
