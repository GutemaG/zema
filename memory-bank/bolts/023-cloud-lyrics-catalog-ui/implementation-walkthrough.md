---
stage: implement
bolt: 023-cloud-lyrics-catalog-ui
created: 2026-10-29T09:40:00Z
---

## Implementation Walkthrough: cloud-lyrics-catalog-ui (bolt 2 of 7)

### Summary

- The phone keeps the catalog's song index in Drift (schema v3).
- The index refreshes at start when it is older than 6 h, and on pull to refresh in
  Search.
- Automatic linking and the Match lyrics picker read from it, so they work offline.
- A link to a song that is no longer in the index counts as no song ("No lyrics").

### Files

- **`zema_core`**:
  - **`SongIdentity`** (in `lyrics_models.dart`): `id`, `title`, `transliteration`,
    `artist`. `Song` and `CatalogEntry` implement it.
  - **`SongMatcher<S extends SongIdentity>`** and
    **`searchSongs<S extends SongIdentity>`**: the same rules, now for either type.
    `songSearchKey` takes a `SongIdentity`.
- **Drift**:
  - **`tables.dart`**: `CatalogSongs` (`CatalogSongRow`): id (primary key), title,
    transliteration, artist, album, synced, version, approvedAt.
  - **`catalog_dao.dart`** (new):
    - `watchEntries()` gives `CatalogEntry`s by ID.
    - `count()`.
    - `replaceAll(entries)`: in one transaction it deletes IDs that are no longer
      listed and upserts the rest.
  - **`zema_database.dart`**: schema version 3, with
    `from2To3: createTable(catalogSongs)`.
  - **Generated** by `build_runner` and `drift_dev make-migrations`:
    - `drift_schemas/zema/drift_schema_v3.json`
    - `test/app/database/zema/generated/schema_v3.dart`
    - the updated `zema_database.steps.dart`
  - **Migration test**: `migration_test.dart` gains "v2 to v3 keeps links and starts an
    empty index". `schema_test.dart` now checks version 3 with nine tables.
- **`features/catalog/application/catalog_index.dart`** (new):
  - **`CatalogIndexRefresher.refresh({force})`** returns `refreshed`, `fresh` or
    `notConfigured`.
    - It skips under `maxAge` (6 h) unless `force` is set.
    - It saves the refresh time under `catalog.indexRefreshedAt`, using `clock`.
    - Overlapping calls share one run.
    - A failure throws the `ZemaFailure` and leaves the index as it was.
  - **Providers**:
    - `catalogIndexRefresherProvider`
    - `catalogEntriesProvider` (a stream from Drift)
    - `catalogStartupRefreshProvider`: one refresh at start; a `ZemaFailure` is only
      logged
- **`app_shell.dart`** keeps `catalogStartupRefreshProvider` alive, listened to before
  link sync.
- **`lyrics_links.dart`**:
  - **`lyricsLinkSyncProvider`** matches tracks against `catalogEntriesProvider`.
  - **`trackSongProvider`** gives a song only when its link ID is in the index. The
    text still comes from `lyricsRepositoryProvider` (the bundled samples) until bolt
    024.
  - **`LyricsLinksController.link`** takes a `SongIdentity`.
- **`match_lyrics_sheet.dart`**: lists and searches `catalogEntriesProvider`, and
  returns a `SongIdentity`.
- **`search_screen.dart`**: a `RefreshIndicator` around both the results and the
  recent searches.
  - Scrolling is always allowed, so you can pull even when the content fits.
  - It calls `refresh(force: true)`.
  - A SnackBar shows `catalogRefreshFailed` on a `ZemaFailure`, or
    `catalogNotConfigured` when the build has no backend.
- **`app_en.arb`**: `catalogRefreshFailed` and `catalogNotConfigured`. Other languages
  fall back to English, as the unit allows.
- **Test helpers**:
  - **`test/helpers/fake_catalog.dart`** (new):
    - `FakeCatalogRepository` serves an index from a `LyricsRepository`, or from given
      entries. It can be set to fail, and it counts calls.
    - `catalogEntry(song)` builds an index entry from a song.
  - **`lyricsOverrides`** also overrides `catalogRepositoryProvider`. By default its
    index lists the bundled samples, filled by the app's own start-up refresh, so
    existing tests link as before.
  - **`pumpZemaApp`** takes a `catalog`.

### Checked

- Analyze is clean in the app and `zema_core`.
- `zema_core`: 201 tests pass. That includes the existing ones, plus matching and
  search giving the same results on `CatalogEntry`s as on `Song`s.
- App: 653 tests pass, the existing ones plus the migration and schema tests.
- The first run had 21 lyrics tests failing while the helpers were half updated; after
  the helper change, all pass.

### Notes

- Bolt 024 replaces `lyricsSongsProvider` (the bundled lyrics) with the catalog cache.
  Until then, song text needs a song in both the index and the bundled samples. The 3
  seeded songs are in both.
- The tests for the refresh rules, removal, pull to refresh and the emulator check come
  in stage 3.
