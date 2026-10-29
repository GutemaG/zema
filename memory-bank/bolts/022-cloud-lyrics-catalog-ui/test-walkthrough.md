---
stage: test
bolt: 022-cloud-lyrics-catalog-ui
created: 2026-10-29T09:10:00Z
---

## Test Walkthrough: cloud-lyrics-catalog-ui (bolt 1 of 7)

### Results

- **pgTAP**: 288 checks pass. That is the 280 from before plus 8 in
  `008_song_index.test.sql`.
- **zema_core**: 199 tests pass, including 9 new ones in `test/catalog/catalog_test.dart`.
- **zema_data**: 28 tests pass.
  - 20 unit tests use a fake HTTP client.
  - 8 run against the local backend.
- **App**: 650 tests pass, including 4 new ones in
  `test/app/backend/backend_providers_test.dart`.
- `flutter analyze` and `dart analyze` are clean everywhere, and `dart format` changes
  nothing.
- `flutter build ios --simulator` builds.

### Tests Added

- **`zema_core` `catalog_test.dart`**:
  - `SongDocument` reads back what it writes, and the shape `CatalogSong.toDocument()`
    writes
  - missing recordings and timings count as none
  - it rejects four kinds of malformed input with `LyricsFormatFailure`
  - `CatalogEntry` compares by value
  - the new failures are `ZemaFailure`s
- **`zema_data` `supabase_catalog_repository_test.dart`** (unit tests, using `MockClient`):
  - **Requests**: each call hits its RPC with the right parameters and the `apikey`
    header, and its answer is parsed.
  - **`get_song` returning `null`** gives null.
  - **Malformed answers** give `LyricsFormatFailure`:
    - a row of the wrong shape
    - an answer that isn't a list
    - a malformed document
  - **Search**: an empty query sends no request.
  - **Reports**:
    - the reasons use the backend's names (all four)
    - a missing recording or note is left out
  - **Error mapping**:
    - PT429 → `RateLimitFailure`
    - PGRST301 and the gateway's 401 → `BackendFailure` ("refused")
    - 22023 → `BackendFailure`
    - 503 → `NetworkFailure`
    - 500 → `BackendFailure`
    - connection refused → `NetworkFailure`
    - a request that never answers times out as a `NetworkFailure` caused by a
      `TimeoutException`
    - reports fail the same way
- **`zema_data` `backend_test.dart`** (tagged `backend`, against the local backend):
  - the index lists every seeded song
  - each `song()` equals what `zema_core` imports from `backend/seed/`
  - an unknown ID gives null
  - search finds a song by its title and by a lyric line
  - five reports are stored, the sixth gives `RateLimitFailure`, and exactly 5 rows
    exist. A random install ID is used and its rows are deleted afterwards.
  - a report for an unknown song gives `BackendFailure`
  - a wrong key gives `BackendFailure`
  - an unreachable port gives `NetworkFailure`; this test runs even with no backend
- **App `backend_providers_test.dart`**:
  - the default config is the emulator URL with no key, so the catalog is null
  - an overridden config with a key gives a `SupabaseCatalogRepository`
  - an empty URL means not configured

### Checks

- **Skip path**: with `npx` failing (a fake `npx` first in `PATH`), the 7 backend tests
  are skipped with "Local backend not running: start it with 'npx supabase start' in
  backend/". The unreachable-backend test still passes.
- **Planted bugs**: each was planted alone and the whole package suite was run. 8 of 8
  are caught:
  - PT429 mapping removed
  - timeout removed
  - wrong reason name
  - empty-query guard removed
  - JWT error mapping removed
  - 503 mapping removed
  - recording ID dropped
  - lenient `synced` parsing
    - It survived the first run: the "wrong shape" row was also missing other fields,
      so it failed for those instead. The row is now complete except for `synced`.

### Not Checked

- **Android emulator**: none was running, and the app doesn't read the catalog yet.
  Reaching `10.0.2.2:54321` from the emulator is checked in bolt 023 or 024, the first
  bolts where the app uses the catalog.
