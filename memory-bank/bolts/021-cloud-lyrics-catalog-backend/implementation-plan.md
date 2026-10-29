---
stage: plan
bolt: 021-cloud-lyrics-catalog-backend
created: 2026-10-29T08:08:00Z
---

## Implementation Plan: cloud-lyrics-catalog-backend (bolt 4 of 4)

### Objective

Load songs from files into the catalog (story 006), starting with the three
placeholder songs. Read each song back in the same JSON shape that `zema_core` uses, so
the app (bolt 022) can parse it directly and a test can prove it matches what the app
bundles today.

### Deliverables

- **`backend/seed/`**: `index.json` and the three `.lrc` files, copied from
  `apps/mobile/assets/lyrics/`.
  - The index format stays the same: id, file, transliteration, durationMs, plus an
    optional `status`.
  - The app keeps its copies until bolt 024 switches it to the catalog, then removes them.
- **`zema_core`**: `importIndexedLrc(entry, lrcText)` in `lrc_import.dart`.
  - It turns one index entry plus its LRC text into a `CatalogSong` (song, recording,
    timing) and checks that the timing fits the lines.
  - This is the logic `BundledLyricsRepository._add` has now, moved so the app and the
    seed share it. The app repository calls it with no change in behaviour, and its
    tests stay green.
- **Migration `…_song_documents.sql`**
  - **`song_document(id) → jsonb`** gives
    `{ "song": Song.toJson(), "recordings": [Recording.toJson()], "timings": [SyncTiming.toJson()] }`:
    - the same keys `zema_core` writes, with optional keys left out
    - play order only when the song has one
    - sources in Dart's naming (`localFile`)
    - internal only
  - **`get_song(id) → jsonb`**, callable by `anon`, returns the document for an
    approved song, or null. Bolt 022's `zema_data` uses it, with one request per song.
  - **`seed_song(doc jsonb, status default 'approved') → text`**:
    - Returns 'unchanged', 'updated' or 'created'.
    - It does nothing when the stored document already equals `doc`, so the
      version doesn't move.
    - Otherwise it upserts the song row and replaces its sections, lines, play order,
      recordings and timings in one transaction.
    - It checks the document's shape and refuses a timing whose length doesn't match
      the sung lines.
    - **Only the service role and postgres** may run it; `anon` and `authenticated`
      can't.
- **Generator `packages/zema_core/tool/generate_seed_sql.dart`**
  - It reads `backend/seed/` and writes `backend/supabase/seed.sql`, one
    `select public.seed_song('<doc>')` per song.
  - A malformed entry or file is skipped and reported on the console, and the rest
    still load.
  - It also writes `tests/database/006_seed.test.sql`, which checks that
    `get_song` returns exactly the documents that `zema_core` produced for every
    seeded song.
  - `config.toml`: `[db.seed]` is turned on, so `npx supabase db reset` loads
    the seed.
  - **No keys needed**: the seed is plain SQL. A hosted project later runs the same
    file with `psql` or `supabase db push --include-seed`.
- **Tests**
  - **pgTAP `007_seed_song.test.sql`** (hand-written):
    - seeding the same document twice gives 'unchanged' with the same version
    - a changed line gives 'updated' and a higher version, with the old line gone from
      search
    - a new ID gives 'created'
    - a timing of the wrong length, or a missing title, is refused
    - `anon` can't call `seed_song`
    - `get_song` returns null for a draft or unknown song
  - **Dart**:
    - `importIndexedLrc` (valid entry, missing id or file, timing that doesn't fit)
    - the seed generator (skips a bad entry and keeps the rest)
    - a staleness test for `seed.sql` and `006_seed.test.sql`
- **README**: a "Seed" section on adding a song (drop the LRC in `backend/seed/`,
  add an index entry, regenerate, `db reset`).

### Technical Approach

- **Generate SQL instead of calling the API**: the seed then needs no Supabase keys or
  HTTP client in `zema_core`, runs inside `db reset`, and is reviewable in git.
- **Exact equality**: `song_document` builds JSON with `jsonb_build_object` and
  `jsonb_strip_nulls`, so key order doesn't matter and missing optional keys compare
  equal. Idempotency and the read-back test both rest on that.

### Acceptance Criteria

- [ ] `npx supabase db reset` loads the three songs as approved
- [ ] Re-running the seed changes nothing (same versions)
- [ ] `get_song` returns exactly `zema_core`'s documents for the bundled songs (generated test)
- [ ] A malformed file is skipped and reported; the rest load
- [ ] Only the service role can seed; `anon` reads approved songs through `get_song`
- [ ] The app's bundled repository still passes its tests using the shared importer
