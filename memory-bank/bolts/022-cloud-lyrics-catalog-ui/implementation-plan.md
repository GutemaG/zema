---
stage: plan
bolt: 022-cloud-lyrics-catalog-ui
created: 2026-10-29T08:32:46Z
---

## Implementation Plan: cloud-lyrics-catalog-ui (bolt 1 of 7)

### Objective

Create `packages/zema_data`, the one place that talks to the catalog backend (story 001).
It fetches the song index, one song with its recordings and timings, search results,
and submits reports. Every backend problem comes back as a `ZemaFailure`. The app gets
the backend address and key from build settings, but nothing in the app uses the
catalog yet; bolts 023–024 switch it over.

### Deliverables

- **`zema_core`: catalog types (pure Dart, no backend code)**
  - **`CatalogEntry`**: one row of the song index. It holds id, title,
    transliteration, artist, album, `synced` (has a timed recording), `version` and
    `approvedAt`.
    - `version` lets bolt 024 tell when a cached song is out of date.
    - `approvedAt` sorts the Home "new lyrics" row (bolt 028).
  - **`SongDocument`**: song, recordings and timings, parsed from the `get_song` JSON.
    It is the same shape `CatalogSong.toDocument()` writes, so it reuses
    `Song/Recording/SyncTiming.fromJson`.
  - **`CatalogSearchHit`**: song id, title, transliteration, artist, score, and the
    matching line (null when the title matched).
  - **`ReportReason`**: `wrongWords`, `wrongTiming`, `wrongSong`, `other`.
    - On the wire these are `wrong_words` and so on, exactly what `submit_report`
      accepts.
  - **`CatalogRepository`** interface:
    - `index()`
    - `song(id) → SongDocument?`
    - `search(query) → List<CatalogSearchHit>`
    - `report(songId, reason, installId, {recordingId, note})`
  - **New failures**:
    - `NetworkFailure`: offline, timeout, server unreachable
    - `RateLimitFailure`: the 6th report in a day
    - `BackendFailure`: wrong key, refused input, server error
    - A missing song is not a failure: `song()` returns null.
- **Backend: migration `…_song_index.sql`**
  - `song_index()` returns the index rows of every approved song (as above) in one
    call.
  - It is `security definer`, granted to `anon` and `authenticated`.
  - **Scope addition**: the backend unit didn't include an index call, and FR-6 needs
    one. Reading the tables directly would take several requests and expose the
    table layout to the app.
  - New pgTAP test `008_song_index.test.sql`:
    - only approved songs are listed
    - `synced` is true only when a timing exists
    - `version` and `approvedAt` are returned
    - `anon` may call it
- **`packages/zema_data`** (new pub workspace member, pure Dart)
  - Dependencies: `zema_core`, `supabase` (2.16.x, the pure-Dart client; no Flutter),
    `http`.
  - **`SupabaseCatalogRepository implements CatalogRepository`**, built from
    `(url, key, {http.Client? httpClient, Duration timeout = 10 s})`.
    - It calls the RPCs `song_index`, `get_song`, `search_songs` and `submit_report`.
    - It parses rows into the `zema_core` types.
  - **Error mapping**, in one function, so no raw exception escapes:
    - socket, client, handshake errors and timeouts → `NetworkFailure`
    - `PostgrestException` code `PT429` → `RateLimitFailure`
    - status 401 or a bad key → `BackendFailure("The backend refused the app's key")`
    - other `PostgrestException`s (for example `22023`) → `BackendFailure`
    - malformed JSON → `LyricsFormatFailure`
  - **Search**: an empty or whitespace-only query returns `[]` without a request.
  - **Report**: `installId` is sent as is; the server stores only its sha256.
- **App: build-time configuration**
  - `lib/app/config/backend_config.dart` reads
    `String.fromEnvironment('ZEMA_BACKEND_URL')` and `ZEMA_BACKEND_KEY`.
  - **Default URL**: `http://10.0.2.2:54321` (the emulator's view of the local
    backend).
  - **No default key**: per the rule "never commit any key".
    - A script `tool/backend_env.sh` writes `apps/mobile/config/backend.local.json`
      from `npx supabase status` (anon key only). That file is gitignored.
    - Run with `flutter run --dart-define-from-file=config/backend.local.json`.
    - Without a key the catalog counts as "not configured", and bolt 023+ treats that
      like being offline.
  - `catalogRepositoryProvider` (Riverpod) builds the repository from the config,
    or is null when no key is set. Nothing reads it yet.
  - The app adds `zema_data` as a dependency. It must build for both Android and iOS.
- **Docs**:
  - `packages/zema_data/README.md`: what it does, how to run its tests
  - a "Run the app against the local backend" note in `backend/README.md`
  - the comment in the workspace `pubspec.yaml`

### Dependencies

- Bolt 021: `get_song`, `search_songs`, `submit_report`, and the seed with three songs.
- The local backend must be running for the integration tests (`npx supabase start`).

### Technical Approach

- **Interface in `zema_core`, implementation in `zema_data`**: `zema_core` stays free
  of backend code (an intent constraint), and later the app's tests and the admin site
  use the same interface with fakes.
- **Classic anon key rather than the new `sb_publishable_…` key**: the local CLI shows
  both, and the Dart client accepts both. The anon JWT works with every hosted project
  setup today. The config name is neutral (`ZEMA_BACKEND_KEY`), so switching later is
  only a configuration change.
- **Timeouts**: the client's `http.Client` is wrapped so every request has a 10 s
  timeout, which then counts as a `NetworkFailure`.
- **No caching here**: storage (Drift) is the app's job in bolts 023–024.
  `zema_data` only talks to the network.

### Tests

- **Unit** (with `http`'s `MockClient`, so no backend is needed):
  - parsing each RPC response
  - each error mapping: socket error, timeout, 401, PT429, 22023, bad JSON
  - an empty query sends no request
- **Integration** (against the local backend, tagged `backend`):
  - the index lists the 3 seeded songs
  - `song()` returns the same document `zema_core` imports from the seed files
  - `song('missing')` returns null
  - a search for "selam" finds its song, and a lyric line comes back with its line
  - a report succeeds, then the 6th within a day gives `RateLimitFailure`. The test
    uses a random install ID, and its reports are removed afterwards through the local
    database URL.
  - a wrong key gives `BackendFailure`
  - an unreachable port gives `NetworkFailure`
  - **When the backend isn't running**: these tests are skipped with "Local backend not
    running: start it with `npx supabase start` in backend/". The key is read from
    `npx supabase status`.
- **pgTAP**: `008_song_index.test.sql`.
- **App**:
  - `backend_config` defaults
  - the provider is null without a key
  - the existing 646 tests stay green, `flutter analyze` is clean, and the iOS build
    compiles

### Acceptance Criteria

- [ ] `packages/zema_data` is a pure-Dart workspace member that depends on `zema_core`
  and `supabase`
- [ ] It fetches the index, a song with recordings and timings, and search results, and
  submits a report, against the local backend
- [ ] Backend down, a timeout (10 s), a wrong key and rate limiting each give a
  `ZemaFailure`, never a raw exception
- [ ] The app reads the URL and key from `--dart-define`; the default URL is
  `10.0.2.2:54321` and no key is committed
- [ ] Analyze and format are clean; all Dart, app and pgTAP tests pass
