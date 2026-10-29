---
stage: plan
bolt: 023-cloud-lyrics-catalog-ui
created: 2026-10-29T08:49:53Z
---

## Implementation Plan: cloud-lyrics-catalog-ui (bolt 2 of 7)

### Objective

Keep a copy of the catalog's song index (no lyrics) on the phone, in Drift (story 002).
Automatic linking and the "Match lyrics" picker then work from it, online or offline.
The index refreshes in the background when the app starts, if it is older than 6 hours,
and on pull-to-refresh in Search. A song removed from the catalog drops out, and its
tracks show "No lyrics".

### Deliverables

- **`zema_core`: `SongIdentity`**
  - A small interface with `id`, `title`, `transliteration` and `artist`.
  - `Song` and `CatalogEntry` both implement it.
  - `SongMatcher` and `searchSongs` become generic over it, so they work on index
    entries as well as full songs. Their behaviour and existing tests are unchanged.
  - New tests run both on `CatalogEntry`s.
- **Drift schema v3**
  - **New table `catalog_songs`**:
    - id (primary key), title, transliteration, artist, album
    - synced, version, approved_at
  - **Migration `from2To3`** creates the table.
    - `drift_schemas/zema/drift_schema_v3.json` and the generated migration test come
      from `dart run drift_dev make-migrations`.
    - Existing links are untouched; the song IDs are the same as the bundled ones.
  - **`CatalogDao`**:
    - `watchEntries()`
    - `replaceAll(entries)`: one transaction that deletes songs no longer in the
      catalog and upserts the rest
    - `count()`
  - **Scope note**: the bolt plan said "v3: index, cached songs, queued reports". Each
    bolt now adds only its own table: v3 the index, v4 the lyrics cache (bolt 024),
    v5 queued reports (bolt 027). Each step is smaller, with its own migration test.
- **App: `features/catalog/`** (new feature folder)
  - **`CatalogIndexRefresher`**: `refresh({bool force = false})`, returning
    `refreshed`, `fresh` (skipped, under 6 h old) or `notConfigured`.
    - It throws the repository's `ZemaFailure` on an error.
    - It fetches `CatalogRepository.index()`, then `dao.replaceAll`, then stores the
      time in shared preferences (`catalog.indexRefreshedAt`).
    - It uses `clock`, so tests control time.
    - Concurrent calls share one request.
  - **Providers**:
    - `catalogEntriesProvider` (a stream from Drift)
    - `catalogIndexRefresherProvider`
    - `catalogStartupRefreshProvider`: kept alive by the app shell, like
      `lyricsLinkSyncProvider`. It calls `refresh()` once at start. A failure is only
      logged, because offline is normal.
- **Linking uses the index**
  - `lyricsLinkSyncProvider` matches tracks against `catalogEntriesProvider`, not the
    bundled songs.
  - `trackSongProvider` treats a link as "no song" when its ID isn't in the index, so a
    removed song shows "No lyrics", not an error.
    - The song's text still comes from `lyricsRepositoryProvider` (the bundled
      samples) until bolt 024 replaces it with the catalog cache.
  - **Match lyrics picker**: lists and searches the index entries, using the same
    `searchSongs`. Picking one links its ID.
- **Search: pull to refresh**
  - A `RefreshIndicator` on Search, on both the results and the recent searches, calls
    `refresh(force: true)`.
  - On failure a SnackBar shows a short message, with new l10n strings:
    - "Couldn't update the song list. Check your connection."
    - "Song list not available in this build" (no backend key)
  - On success there is no message; the lists simply update.
- **Edge cases**:
  - **First launch offline**: the index is empty and links stay empty. Tracks show "No
    lyrics" and nothing errors.
  - **No backend key** (`catalogRepositoryProvider` is null): refresh returns
    `notConfigured` and nothing is fetched.

### Dependencies

- Bolt 022: `CatalogRepository`, `catalogRepositoryProvider`, `song_index()`.

### Technical Approach

- **Interface over conversion**: matching needs only the title, transliteration and
  artist. A shared `SongIdentity` avoids fake `Song`s with empty sections, and avoids a
  second copy of the matching rules.
- **Last refresh time in shared preferences, not Drift**: it is one value. Losing it
  only causes one extra refresh.
- **Full replace, not delta**: delta sync is out of scope. 5,000 rows replace in one
  transaction in well under a second.
- **Between this bolt and 024**: linking follows the catalog, but the lyrics text comes
  from the bundled samples. The 3 seeded songs have the same IDs, so they link and show
  as today when the app has a backend key. Without a key the index stays empty, which
  is where 024 ends up anyway once the bundled lyrics are removed.

### Tests

- **`zema_core`**: `SongMatcher` and `searchSongs` give the same results on
  `CatalogEntry`s as on `Song`s.
- **Drift**:
  - the v2 → v3 migration (generated test), with existing links surviving
  - `schema_test` is version 3, with nine tables
  - `CatalogDao.replaceAll` removes, updates and adds in one go
  - `watchEntries` emits after each change
- **Refresher** (fake `CatalogRepository` with `fake_async`/`clock`):
  - a missing index refreshes
  - under 6 h it is skipped; over 6 h it refreshes
  - `force` always refreshes
  - a failure keeps the old index and rethrows
  - `notConfigured` when there is no repository
  - two concurrent calls make one fetch
- **Providers / widgets**:
  - startup triggers one refresh, and a failure doesn't crash
  - tracks link from the index while offline (no repository)
  - a song removed on refresh unlinks automatic links, and a manual link shows "No
    lyrics"
  - the picker searches index entries
  - pull-to-refresh in Search calls refresh and shows the SnackBar on failure
- All existing tests pass, with fakes updated to seed the index.
- `flutter analyze` is clean and the iOS build compiles.
- **On the Android emulator** with `backend.local.json`: the index loads from the local
  backend, the sample tracks link, and pull to refresh works. A second run with the
  backend stopped shows the failure message, and links still work.

### Acceptance Criteria

- [ ] Starting online with an index older than 6 h (or none) refreshes it in the
  background into Drift v3
- [ ] Offline, automatic linking and the picker's title search use the last index
- [ ] A song removed from the catalog drops out on refresh, and its tracks show "No
  lyrics", not an error
- [ ] Pull to refresh in Search refreshes the index, and a failure shows a short message
- [ ] Analyze clean, all tests pass, iOS builds, checked on the emulator
