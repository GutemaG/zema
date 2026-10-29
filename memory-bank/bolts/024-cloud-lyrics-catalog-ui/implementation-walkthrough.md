---
stage: implement
bolt: 024-cloud-lyrics-catalog-ui
created: 2026-10-29T10:30:00Z
---

## Implementation Walkthrough: cloud-lyrics-catalog-ui (bolt 3 of 7)

### Summary

- The app reads lyrics from the cloud catalog.
- A song is downloaded the first time it is needed, then saved in Drift (schema v4)
  and read from there. When the index shows a newer version, the song is downloaded
  again.
- A song that was never downloaded, opened without a network, shows C07 offline with
  "Try again".
- The sample lyrics are no longer in the app; they are test fixtures.

### Files

- **Drift**
  - **`tables.dart`**: `CachedSongs` (`CachedSongRow`): id (primary key), version,
    `document` (the whole `SongDocument` as JSON), cachedAt.
  - **`cached_songs_dao.dart`** (new):
    - `song(id)` gives `(document, version)`, or null. A row that no longer decodes
      counts as not cached.
    - `save(document, version)` is one upsert.
    - `watchSongs()`.
  - **`catalog_dao.dart`**: `entry(id)`.
  - **`zema_database.dart`**: version 4, with `from3To4: createTable(cachedSongs)`.
  - **Generated**: `drift_schema_v4.json`, `schema_v4.dart` and the steps file.
- **`features/catalog/data/catalog_lyrics_repository.dart`** (new)
  - **`lyricsRepositoryProvider`** now lives here.
  - **`CatalogLyricsRepository.document(id)`**:
    - A song not in the index gives null.
    - A copy in memory or Drift at the index's version, or newer, is used as is.
    - Otherwise the song is fetched and saved.
    - On a `ZemaFailure`, an older copy is used if there is one; otherwise the failure
      is rethrown.
    - Fetches of the same song share one request.
    - With no backend, a fetch is a `NetworkFailure`.
  - **`recordings`, `timing`, `songs`, `search`** read the cache only, limited to
    songs the index still lists.
- **`lyrics_links.dart`**
  - **New `songProvider(id)`** (a FutureProvider family, with retry turned off):
    - It waits for the index, and gives null when the song isn't listed.
    - Otherwise it calls `repository.song`.
    - It watches only its own index entry (`select` + `whenData`), so a new version
      or a removal rebuilds it, and other songs' changes don't.
  - **`trackSongProvider`**: link, then `songProvider(linked id)`.
  - **`lyricsSongsProvider`**: now a stream of the cached songs the index lists. It
    feeds the lyric-line search.
- **`lyrics_view.dart`**: new `LyricsUnavailable`.
  - A `NetworkFailure` shows the C07 offline state; any other error shows the C07
    error state.
  - "Try again" invalidates `songProvider`.
  - Now Playing shows it when `trackLyricsProvider` fails.
- **`song_detail_screen.dart`**:
  - The screen uses `songProvider(id)`.
  - Song not found: shows C07 not found.
  - Download failed: shows `LyricsUnavailable` with an app bar.
  - The song stays on screen while a newer version downloads.
- **`app_en.arb`**: `lyricsOfflineTitle`, `lyricsOfflineMessage`,
  `lyricsLoadFailedTitle`, `lyricsLoadFailedMessage`. The button reuses
  `actionTryAgain`.
- **Samples removed**
  - **Moved**:
    - `assets/lyrics/` → `test/fixtures/lyrics/`, and the asset line was removed from
      `pubspec.yaml`
    - `BundledLyricsRepository` → `test/helpers/bundled_lyrics_repository.dart`, with
      `DiskAssetBundle`; its test moved beside it
  - **`tool/test_audio.sh`** reads the fixtures.
  - **The `LyricsRepository` comment** in `zema_core` is updated.
- **Test helpers**
  - **`lyricsOverrides`** no longer overrides `lyricsRepositoryProvider`. Tests run
    the real `CatalogLyricsRepository`, with Drift, against `FakeCatalogRepository`.
  - **`FakeCatalogRepository`**:
    - It serves documents from `lyrics` even when `entries` are given.
    - It adds `versions` (index versions) and `songCalls`.
  - **New `cacheSampleLyrics(db)`**, for tests that search lyric lines.

### Bugs Found While Implementing

- **A fetch that never finished**:
  - `whenComplete(() => _fetching.remove(id))` returned the removed future, which is
    the `whenComplete` future itself, so it waited for itself.
  - Fixed with a block body, and commented.
- **`selectAsync`** left `songProvider` loading after its song was removed from the
  index. It was replaced by `select` + `whenData`, the pattern `trackLyricsProvider`
  already uses.
- **Removed-song test, test-side fix**: the test read providers nobody listened to.
  Riverpod 3 doesn't rebuild those until they're read, so the read caught them
  half-way. The test now listens, as a screen does.

### Checked

- `flutter analyze` is clean, and `dart format` changes nothing.
- **App: 679 tests pass.**
  - That includes the existing ones, now running through the catalog cache.
  - Plus the v3→v4 migration test.
  - The schema test now checks v4, with ten tables.
- **Lyric search tests** cache the samples first, because line search covers cached
  songs until bolt 025.

### Notes

- **Search is cached-only until 025**: lyric-line search finds only songs already
  downloaded. Bolt 025 adds the server's search.
- **Stage 3** covers the repository's own tests, the offline and Try again widget
  tests, the timing check and the emulator check.
