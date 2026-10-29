---
stage: test
bolt: 021-cloud-lyrics-catalog-backend
created: 2026-10-29T08:16:30Z
---

## Test Report: cloud-lyrics-catalog-backend (bolt 4 of 4)

### Summary

- **pgTAP**: 7 files pass on a freshly seeded database:
  - 28 schema
  - 31 read rules
  - 17 reports
  - 170 search parity
  - 14 search index
  - 4 generated seed read-back
  - 16 seed_song
  - **280 checks**
- **Dart**:
  - `zema_core` 190/190, including the importer, the seed generator and staleness tests for both generators.
  - The app's suite passes 646/646 with `flutter analyze` clean. The bundled repository now uses the shared importer.
- **Planted bugs**: 12/12 caught.
  - **Document functions** (each checked with `db reset`, which re-seeds, then `test db`):
    - always rewriting
    - `offsetMs: 0` kept in documents
    - lines ordered by text
    - timing length unchecked
    - drafts served by `get_song`
    - `anon` allowed to seed
    - raw source names (`local_file`) served
    - a status change ignored when the content matches
    - old parts kept on update
  - **Dart**:
    - duplicate IDs allowed in the seed
    - duration ignored by `importIndexedLrc`
    - transliteration ignored
- **Rerunning the seed**: `seed.sql` again prints `unchanged` ×3, with versions unchanged (implement stage).
- **API**: `get_song` serves Galatoomi to `anon`, and `seed_song` returns `42501` (implement stage).

### Acceptance Criteria (story 006)

- ✅ The seed folder (index + LRC) loads into the backend as approved songs
- ✅ Running it again changes nothing (`unchanged`, same version)
- ✅ The placeholder songs read back equal to the bundled versions: same IDs, sections, play order and timings (generated `006_seed.test.sql`)
- ✅ A malformed file or entry is skipped and reported; the rest load (`buildSeed` test)

### Backend Unit Complete

Bolts 018–021 finish `001-cloud-lyrics-catalog-backend`:
- a local Supabase project with the schema
- read-only access to approved songs, and rate-limited reports
- search generated from `zema_core`
- the seed and `get_song`

Next is the app side, starting with `zema_data` (bolt 022).
