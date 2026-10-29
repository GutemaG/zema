---
stage: implement
bolt: 022-cloud-lyrics-catalog-ui
created: 2026-10-29T08:55:00Z
---

## Implementation Walkthrough: cloud-lyrics-catalog-ui (bolt 1 of 7)

### Summary

- **`packages/zema_data`**: the one place that talks to the catalog backend.
  - It fetches the song index, one song with recordings and timings, and search
    results, and submits reports.
  - Every error comes back as a `ZemaFailure`.
- **The app** now knows where the backend is, from build settings. It doesn't use the
  catalog yet; bolts 023–024 switch it over.
- **One backend addition**: `song_index()`, which lists every approved song in one
  call.

### Files

- **`packages/zema_core/lib/src/catalog/catalog.dart`** (new, exported):
  - **`CatalogEntry`**: id, title, transliteration, artist, album, `synced`,
    `version`, `approvedAt`.
  - **`SongDocument`**: song, recordings and timings.
    - `fromJson`/`toJson` use the `get_song` / `CatalogSong.toDocument()` shape.
    - It reuses the models' own parsers, so a malformed document gives
      `LyricsFormatFailure`.
  - **`CatalogSearchHit`**: song fields, score, and the matching line (null when the
    title matched).
  - **`ReportReason`** and the **`CatalogRepository`** interface.
- **`packages/zema_core/lib/src/failures.dart`**: three new failures,
  `NetworkFailure`, `RateLimitFailure` and `BackendFailure`.
  - No code switches over every failure type, so adding them breaks nothing.
- **`backend/supabase/migrations/20261029040000_song_index.sql`**: `song_index()`
  returns the index rows of approved songs, ordered by ID.
  - `synced` means some recording of the song has a timing.
  - It is `security definer`, granted to `anon` and `authenticated`.
- **`backend/supabase/tests/database/008_song_index.test.sql`**: 8 checks.
  - only approved songs are listed
  - `synced` is true only with a timing
  - the fields come back
  - an edit raises `version`
  - a song moved back to draft drops out
  - `anon` may call it
- **`packages/zema_data/`** (new workspace member): pubspec, analysis options (same as
  `zema_core`) and README.
  - **`SupabaseCatalogRepository`** (`lib/src/supabase_catalog_repository.dart`)
    calls `song_index`, `get_song`, `search_songs` and `submit_report`.
    - **Timeout**: a wrapping `http.Client` gives up on any request after 10 s.
    - **Search**: an empty query sends no request.
    - **Reasons** are sent as `wrong_words` and so on.
    - **`close()`** disposes of the client and its JSON isolate.
  - **Error mapping**, in one function:
    - `PT429` → `RateLimitFailure`
    - `PGRST301`/`302`, 401 or 403 → `BackendFailure` ("refused the app's key")
    - 502/503/504 → `NetworkFailure`
    - other PostgREST errors → `BackendFailure`
    - anything with no server answer (connection refused, TLS error, timeout) →
      `NetworkFailure`
    - a row of the wrong shape → `LyricsFormatFailure`
  - **No `dart:io`**: socket errors arrive wrapped as `http.ClientException`, so the
    package also compiles for the admin website (Flutter web).
- **`apps/mobile/lib/app/backend/`**:
  - **`backend_config.dart`**: `BackendConfig.fromEnvironment()` reads
    `ZEMA_BACKEND_URL`, defaulting to `http://10.0.2.2:54321`, and
    `ZEMA_BACKEND_KEY`, which has no default.
  - **`backend_providers.dart`**:
    - `backendConfigProvider`
    - `catalogRepositoryProvider`, which is null without a key and closes the
      repository with its scope
- **`apps/mobile/tool/backend_env.sh`**: writes `config/backend.local.json` (URL and
  anon key) from `npx supabase status`.
  - It takes an optional URL, for a real phone on the LAN.
  - The `.gitignore` excludes `apps/mobile/config/*.local.json`.
- **`apps/mobile/pubspec.yaml`** depends on `zema_data`; the workspace `pubspec.yaml`
  lists it.
- **`backend/README.md`**: "run the app against the local backend", plus
  `song_index()`.

### Checked

- `dart analyze` is clean in `zema_core` and `zema_data`; `flutter analyze` is clean
  in the app.
- 288 pgTAP checks pass (280 before + 8).
- **Smoke run against the local backend**:
  - the index lists the 3 seeded songs (versions 17–18)
  - `song('galatoomi')` parses
  - `song('nope')` is null
  - "selam" finds `selam-lezih-bet`
  - a wrong key gives `BackendFailure`
  - port 1 gives `NetworkFailure` (connection refused)

### Note

- **Each repository holds a JSON isolate**: a client that isn't `close()`d keeps a Dart
  process alive. The provider closes it, and the tests close every client in
  `tearDown`.
