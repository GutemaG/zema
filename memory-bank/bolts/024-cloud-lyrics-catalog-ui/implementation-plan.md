---
stage: plan
bolt: 024-cloud-lyrics-catalog-ui
created: 2026-10-29T09:46:13Z
---

## Implementation Plan: cloud-lyrics-catalog-ui (bolt 3 of 7)

### Objective

The app reads lyrics from the cloud catalog instead of the bundled samples (story
003). A song's lyrics are fetched the first time they are needed, saved in Drift, and
read from there afterwards, so they work offline. When the index shows a newer version,
the song is fetched again on its next use. Opening an uncached song with no network
shows the C07 offline state with Retry. The app no longer ships the sample lyrics;
tests keep them as fixtures.

### Deliverables

- **Drift schema v4**
  - **New table `cached_songs`**: song id (primary key), version, the whole
    `SongDocument` as JSON text, and the time it was saved.
    - One row per song, written in one statement, so a failed or half-finished fetch
      never leaves part of a song in the cache.
  - **Migration `from3To4`** creates the table, with the generated schema files and a
    v3→v4 migration test (links and index kept, cache empty).
  - **`CachedSongsDao`**: `document(id)`, `save(document, version)`, and
    `watchDocuments()` (every cached song, by ID).
- **`CatalogLyricsRepository`** (`features/catalog/data/`), implementing
  `LyricsRepository` from the index, the cache and the `CatalogRepository`:
  - **`song(id)`**:
    - A song not in the index gives null.
    - A cached copy at the index's version, or newer, is read from Drift with no
      network call.
    - Otherwise the song is fetched, saved, and returned. If the server no longer has
      it, the result is null.
    - **Offline**: if a fetch fails and an older copy is cached, the old copy is shown
      and the failure is logged. With no copy, the `ZemaFailure` is thrown, and the
      screen shows C07.
    - Fetches of the same song at the same time share one request.
  - **`recordings`, `timing`, `songs`, `search`** read the cached documents only.
    Search is unchanged until bolt 025 merges in server search.
  - **No backend in the build**: the cache and the empty index still work; nothing is
    fetched.
- **Providers**
  - **`lyricsRepositoryProvider`** moves to `catalog_lyrics_repository.dart` and gives
    the catalog repository.
  - **New `songProvider(id)`**: one song, fetched or cached. It is rebuilt when that
    song's index version changes, which covers "refreshes on next use".
  - **`trackSongProvider`** uses `songProvider` for the linked song, so linking no
    longer needs every song's text.
  - **`lyricsSongsProvider`** becomes the cached songs (a stream from the cache), for
    the lyric-line search.
  - **`trackLyricsProvider`** is unchanged; it already reads recordings and timing
    through the repository.
- **Offline state (C07)**
  - **Now Playing lyrics**: when the song can't be fetched, show
    `EmptyState(kind: offline)` with Retry, which invalidates `songProvider` for that
    song. Other failures show the error kind.
  - **Song detail (S07)**: uses `songProvider(id)`, so opening a song fetches it. The
    same offline state with Retry shows when it can't be fetched, and "not found"
    shows when the song isn't in the catalog.
  - **New strings in `app_en.arb`**:
    - `lyricsOfflineTitle`: "You're offline"
    - `lyricsOfflineMessage`: "These lyrics haven't been downloaded yet. Connect to
      the internet and try again."
    - `lyricsLoadFailedTitle`: "Couldn't load the lyrics"
    - A Retry string, reused if one already exists.
- **Bundled samples removed**
  - `apps/mobile/assets/lyrics/` moves to `apps/mobile/test/fixtures/lyrics/`, and
    the asset entry is removed from `pubspec.yaml`.
  - `BundledLyricsRepository` moves to the test helpers, where it loads the fixtures
    from disk.
  - **Tests**:
    - `FakeCatalogRepository` already serves those fixtures as an index and as song
      documents.
    - `lyricsOverrides` stops overriding `lyricsRepositoryProvider`, so tests run the
      real `CatalogLyricsRepository` against the fake catalog.

### Dependencies

- Bolt 023: the index (`CatalogDao`, `catalogEntriesProvider`).
- Bolt 022: `CatalogRepository.song(id)` and the `NetworkFailure` type.
- The local backend's seed has the same 3 songs as the fixtures, for the emulator
  check.

### Technical Approach

- **Storing JSON**: the cache stores `SongDocument.toJson()` as one text column,
  rather than normalized tables. A song is always read whole, and one row per song is
  what makes "nothing partial is cached" simple to keep true.
- **Speed**: decoded documents are kept in memory once read. A cached song shows in
  under 300 ms; a test measures the cached read.
- **Retry**: invalidates `songProvider(id)`. The repository doesn't remember a
  failure, so Retry fetches again.

### Acceptance Criteria → Tests

| Criterion | Test |
|-----------|------|
| Fetched, saved, shown; later opens read the cache | repository test (a second read makes no network call); widget test, Now Playing shows the fetched lyrics |
| A newer index version refreshes on next use | repository test; provider test (an index change rebuilds `songProvider`) |
| No network, uncached → C07 with Retry | widget tests in Now Playing and song detail; Retry then shows the lyrics |
| No bundled lyrics in the build | the asset is gone from `pubspec.yaml`; tests read the fixtures |
| Cached song in < 300 ms | timed repository test |
| A failed fetch caches nothing | repository test: a fetch fails, then the cache is still empty |

### Emulator Check

1. Install fresh with the backend running, so the index is fetched.
2. Stop the backend, then open Galatoomi. Expected: offline state.
3. Start the backend and tap Retry. Expected: the lyrics show.
4. Stop the backend again. Expected: the lyrics still show from the cache, in Now
   Playing and in song detail.
