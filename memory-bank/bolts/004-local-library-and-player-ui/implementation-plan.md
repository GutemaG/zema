---
stage: plan
bolt: 004-local-library-and-player-ui
created: 2026-10-24T19:30:00Z
---

## Implementation Plan: local-library-and-player-ui (bolt 1 of 5)

### Objective

Read the phone's audio files reliably and keep them in Zema's own database with stable
IDs. Prove the MediaStore scanner on an Android emulator first (spike), then build the
Drift database, the audio permission flow, and the scan-and-sync pipeline. The Library
tab gets only the permission, scanning, error and a temporary plain list of the synced
tracks; the real Tracks screen comes in bolt 005.

Stories: 001-library-scanner-spike, 002-library-database, 003-audio-permission,
004-library-scan-and-sync.

### Deliverables

**0. Test device and files** (not shipped in the app)
- Android emulator `zema_api37` from the installed `android-37.0;google_apis_playstore;arm64-v8a` image
- `apps/mobile/tool/test_audio.sh`: generates test MP3s with `ffmpeg` into a git-ignored
  folder and pushes them with `adb push`, then triggers a media scan. The files:
  - tagged tracks in `Music/Zema Test` (Latin and Ethiopic titles, artists, albums,
    track numbers, years)
  - `Download/` and `Telegram/Telegram Audio/` files (folder variety)
  - a folder with an Ethiopic name (`Music/መዝሙር`)
  - a 10 s "voice note" (must be excluded) and a file with no tags (title from file name)
  - `--bulk 1000` option for the scan-time check

**1. Scanner spike (story 001)**, in this order; implement stops after this step and
reports the result before going on
1. `on_audio_query` 2.9.0: does it build with AGP/Gradle of Flutter 3.47 and return every
   test file with all fields on Android 37?
2. If not: a Kotlin `MethodChannel` `com.zemaapp.zema/library` querying
   `MediaStore.Audio.Media` (scan) and `ContentResolver.loadThumbnail` (art), using the
   old `MusicRepository.kt` as reference. The maintained fork `on_audio_query_pluse` is
   not used, to avoid depending on a single small maintainer.
- Either way, the app sees only `LibraryScanner` (`scan()`, `loadArtwork(id, size)`),
  plus `UnsupportedLibraryScanner` on iOS and `FakeLibraryScanner` in tests.
- Decision recorded in the implementation walkthrough and `standards/tech-stack.md`.

**2. Domain in `packages/zema_core/lib/src/`** (story 002)
- `library/scanned_audio.dart`: one MediaStore entry (ID, content URI, path, title,
  artist, album, album artist, track number, year, duration, size, date added)
- `library/track.dart`: Zema's track (Zema ID, MediaStore ID, URI, path, folder,
  metadata, `missing`) with `==`, `hashCode`, `copyWith`
- `library/track_fingerprint.dart`: size + duration rounded to 1 s + normalized title
  (trim, lowercase, collapse spaces; Ethiopic unchanged)
- `library/reconcile_tracks.dart`: stored tracks + scan → inserts, updates (path match),
  moves (fingerprint match), missing, returned. A fingerprint that matches more than one
  stored track is treated as a new file.
- `failures.dart`: the sealed `ZemaFailure` from the coding standards, with the subtypes
  needed now: `PermissionFailure`, `ScanFailure`, `DatabaseFailure`
- Exported from `zema_core.dart`

**3. Drift database in `apps/mobile/lib/app/database/`** (story 002)
- `zema_database.dart`, schema version 1, tables: `tracks`, `hidden_folders`,
  `hidden_tracks`, `favorites`, `playlists`, `playlist_entries`, `play_events` (all
  created now so later bolts only add DAOs; foreign keys on, cascades from playlists to
  entries)
- `library_dao.dart`: watch visible tracks, apply a reconciliation in one transaction,
  hide and unhide (used by later bolts; tested now)
- `drift_schemas/` schema dump of version 1 and a generated migration test harness, so
  version 2 (lyrics cache in 003) adds a tested step
- `databaseProvider`, opened with `drift_flutter`, closed on dispose

**4. Audio permission (story 003)** in `lib/features/library/`
- `data/audio_permission_service.dart`: interface (status, request, open settings) and the
  `permission_handler` implementation (`Permission.audio` on 13+, `Permission.storage`
  on 12 and older)
- `application/library_access_controller.dart`: status (unknown, granted, denied,
  permanently denied, unsupported on iOS), re-checked on app resume. A saved flag means
  the explanation is shown only once.
- `presentation/library_permission_view.dart`: the explanation with Allow / Not now, and
  C07 states for denied (Grant access), permanently denied (Open settings) and iOS
  (Not available on iOS yet)
- Manifest: `READ_MEDIA_AUDIO`; `READ_EXTERNAL_STORAGE` with `maxSdkVersion="32"`

**5. Scan and sync (story 004)**
- `data/library_repository.dart`: scan → reconcile → apply; logs count and time at INFO
  (no paths in release)
- `application/library_sync_controller.dart`: idle / scanning / failed, last result; one
  scan at a time; started in the background on app start (from `AppShell`) when access
  is granted, on grant, and by `rescan()`
- `application/library_providers.dart`: `libraryTracksProvider`, which hides missing
  tracks, tracks in hidden folders, hidden tracks, and audio shorter than 30 s. The value
  will become a setting in story 020.
- `presentation/library_screen.dart`: permission states; spinner on the first scan; C07
  error with "Try again" when nothing is stored; a snackbar when a stored library exists;
  temporary plain list (title, artist or "Unknown artist", track count)
- "Unknown artist" / "Unknown album" and all new strings in `app_en.arb`

### Dependencies

- `on_audio_query` ^2.9.0 (spike; removed if it fails)
- `drift` ^2.35, `drift_flutter` ^0.3, dev: `drift_dev` ^2.35, `build_runner` ^2.17:
  database and code generation
- `permission_handler` ^13.0: audio permission
- `path` (already transitive): folder from file path
- **Homebrew `ffmpeg`** on this Mac, for generating test MP3s (dev tool only, never in
  the app)
- No `just_audio` / `audio_service` yet (bolt 005)

### Technical Approach

- **Zema ID** is an auto-increment integer. Re-linking after a reinstall (005) uses the
  fingerprint, not the ID, so a UUID adds nothing here.
- **Generated code is committed**: Drift's `*.g.dart`, like the l10n output. CI stays
  simple and needs no `build_runner` step. Generated files stay excluded from analysis.
- **Layering**: the UI reads providers only. The repository is the only code that
  touches the scanner and the DAO. Reconciliation is pure Dart and has no Drift types.
- **Background scan**: the stored list is a Drift stream, so the screen shows data
  before the scan ends. The sync runs reconcile and apply in one transaction, so a
  failure leaves the old library untouched.
- **Folder** is the parent directory of `path`. If `path` is empty (scoped storage),
  it's built from `RELATIVE_PATH` + display name.
- **iOS**: `UnsupportedLibraryScanner`, and the permission service reports
  "unsupported", so iOS never calls MediaStore code.
- **Errors**: `PlatformException` maps to `PermissionFailure` / `ScanFailure`, and a
  database open error maps to `DatabaseFailure` (logged as SEVERE, shown as C07 error).

### Acceptance Criteria

Story 001
- [ ] Emulator lists every test file with title, artist, album, duration, size, path and date added
- [ ] Scanner decision (plugin or Kotlin) recorded in the walkthrough and `tech-stack.md`
- [ ] App code depends only on `LibraryScanner`; iOS uses `UnsupportedLibraryScanner` and the iOS build compiles
- [ ] `FakeLibraryScanner` used in tests; platform errors map to `PermissionFailure` / `ScanFailure`

Story 002
- [ ] Fresh install creates schema version 1 with all seven tables
- [ ] Rescan matches by path, then fingerprint; matched tracks keep their ID and get updated metadata
- [ ] A moved file keeps its ID; all-new MediaStore IDs change no Zema IDs
- [ ] Missing tracks are marked, not deleted, and return with the same ID
- [ ] An ambiguous fingerprint becomes a new track
- [ ] Reconciliation unit-tested in `zema_core` (with Ethiopic titles); DAO and migration harness tested in memory

Story 003
- [ ] Explanation with Allow / Not now before the system dialog; shown once
- [ ] Granted → scan starts without restart; denied → C07 Grant access; permanently denied → system settings, and returning with access starts the scan
- [ ] Correct permission per Android version; iOS shows "Not available on iOS yet" without asking
- [ ] Fake permission service covers all states, including returning from settings

Story 004
- [ ] Stored library shows at once; background scan on start; list updates when done
- [ ] Under 30 s excluded; hidden folders and tracks excluded; deleted files disappear
  (stored entries kept)
- [ ] Unknown artist/album localized; title falls back to the file name
- [ ] Failed scan: C07 "Try again" when empty, snackbar when a library exists; no double scans
- [ ] 1,000-file scan time measured on the emulator and logged (release target < 5 s on a
  mid-range phone stays open until a real phone is available)

Quality
- [ ] `flutter analyze`, `dart format`, `flutter test`, `dart test` clean; existing 141 tests still pass
- [ ] App runs on the emulator and still runs on the iOS simulator
