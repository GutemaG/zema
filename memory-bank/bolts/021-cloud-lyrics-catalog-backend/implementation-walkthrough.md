---
stage: implement
bolt: 021-cloud-lyrics-catalog-backend
created: 2026-10-29T08:12:35Z
---

## Implementation Walkthrough: cloud-lyrics-catalog-backend (bolt 4 of 4)

### Summary

- `npx supabase db reset` now loads the three placeholder songs from `backend/seed/`.
- The backend serves each song as a document in `zema_core`'s JSON shape (`get_song`).
- A generated test proves those documents equal what `zema_core` produces from the
  same files.
- Seeding is idempotent and closed to app users.

### Files

- **`packages/zema_core/lib/src/lyrics/lrc_import.dart`**
  - **`CatalogSong`**: song, recording, timing and skipped lines, with `toDocument()`.
  - **`importIndexedLrc(entry, lrc)`**: the index-entry logic moved from the app.
    - It checks the timing fits.
    - The recording ID is the song ID.
    - It takes the transliteration and duration from the entry.
- **`apps/mobile/.../bundled_lyrics_repository.dart`**: `_add` uses `importIndexedLrc`. Its behaviour is unchanged, and its 7 tests pass.
- **`backend/seed/`**: `index.json` (with a note on how to add songs) and the 3 LRC files, copied from the app. The app's copies go in bolt 024.
- **`backend/supabase/migrations/20261029030000_song_documents.sql`**
  - **Name mapping**: `recording_source_name` and `recording_source_from_name` map Dart's `localFile` to the database's `local_file`.
  - **`song_document(id)`**:
    - built with `jsonb_build_object` and `jsonb_strip_nulls`, so optional keys are left out as in Dart
    - play order only when present
    - `offsetMs` only when it isn't 0
    - not executable by `anon` or `authenticated`
  - **`get_song(song_id)`**: `security definer`, approved songs only, callable by `anon`.
  - **`seed_song(doc, status default 'approved')`**:
    - **Checks**: it needs `song.id`, `song.title` and a sections list, and every timing must have exactly one start per sung line (playOrder, or the sections in order).
    - **`'unchanged'`** when the stored document and status already match. The version doesn't move.
    - **Status-only change**: it updates just the status.
    - **Otherwise**: it upserts the song and replaces its sections, lines, play order, recordings and timings. The search index follows through the existing triggers.
    - Only `service_role` (and postgres) may run it.
- **`packages/zema_core/tool/seed_sql.dart`** and **`generate_seed_sql.dart`**
  - `buildSeed` reads the index plus files and skips, with a reason:
    - a missing file
    - LRC with no timed lines
    - an entry without an ID or file, or one that isn't an object
    - an unknown status
    - a duplicate ID
  - It writes `supabase/seed.sql` (one `seed_song` call per song) and `tests/database/006_seed.test.sql`. As `anon`, that test checks `get_song` equals each document, and that exactly the approved seed songs are visible.
- **`supabase/config.toml`**: `[db.seed]` is enabled.
- **Earlier pgTAP files** (001, 002, 003, 005 and the generated 004) now start with `delete from public.songs` inside their rolled-back transaction, because the database is no longer empty.
- **New tests**:
  - `007_seed_song.test.sql` (16 checks)
  - `test/lyrics/indexed_lrc_test.dart` (4)
  - `test/seed_sql_test.dart` (4, including staleness)
- **`backend/README.md`**: a Seed section (add a song, regenerate, reset; reruns are safe; hosted later) and the layout.

### Checked

- `db reset` prints "Seeding data from supabase/seed.sql…", and all 7 pgTAP files pass.
- Running `seed.sql` again prints `unchanged` three times, and the versions stay at 18, 17 and 17.
- **Through the API with the anon key**:
  - `rpc/get_song` for "galatoomi" returns the title, the play order `[v1, c, v2, c, c]`, 10 starts and the recording (bundled, 43000 ms).
  - `rpc/seed_song` is refused with `42501`.
- The core suite passes 190/190.

### Note

- **Starting versions**: a seeded song's version starts around 17. Each inserted part bumps it, and only increases matter.
