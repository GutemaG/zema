---
stage: test
bolt: 004-local-library-and-player-ui
created: 2026-10-24T20:01:41Z
---

## Test Report: local-library-and-player-ui (bolt 1 of 5)

### Summary

- **Tests**: 227/227 passed (206 in `apps/mobile`, up from 140; 21 in `packages/zema_core`, up from 1)
- **Coverage**: 92.2% of lines (940/1019) in `apps/mobile/lib/` excluding generated code (Drift `*.g.dart`, l10n). Without `tables.dart` it is 96.6%: that file holds Drift's table declarations, which the code generator reads but nothing runs. The uncovered lines are:
  - the real platform choices (`databaseProvider`, scanner and permission providers)
  - the real "open app settings" call
  - the tracks-stream error state
- **CI sequence run locally**: format check, `flutter analyze`, `flutter test`, `dart analyze`, `dart test` all exit 0. Generated localizations are in sync.
- **Devices**: Android emulator (Android 37) and iOS simulator, by hand (see below).

### Test Files

- [x] `packages/zema_core/test/library/reconcile_tracks_test.dart` - path match; unchanged rescan writes nothing; all-new MediaStore IDs keep Zema IDs; moved files re-linked (Latin and Ethiopic titles, spacing differences); size change means a new file; duration rounding; two ambiguity cases treated as new; missing marked, not re-reported, returning at the same or a new path; duplicate paths in a scan; fingerprint normalization; title fallback; `folderOf`
- [x] `apps/mobile/test/features/library/data/media_store_library_scanner_test.dart` - every field of a channel row; `<unknown>` and blank tags become no tag; number widths and nulls; empty result; `permission_denied` → `PermissionFailure`, other errors and a missing channel → `ScanFailure`; artwork arguments; the unsupported scanner
- [x] `apps/mobile/test/features/library/data/audio_permission_service_test.dart` - `READ_MEDIA_AUDIO` on 13+, storage on 12 and older, new-Android default when the version is unknown; every `PermissionStatus` mapped; the dialog's answer returned; the unsupported service
- [x] `apps/mobile/test/app/database/library_dao_test.dart` - round-trip with Ethiopic tags and UTC dates; unchanged rescan; moved file keeps its ID and a missing one is hidden; title sort ignoring case; 30 s minimum; hide/unhide a track; a hidden folder hides subfolders but not `Music Videos` or `Music_x`; hiding twice; the stream updates on every change; a failing write rolls back the whole scan; foreign keys enforced
- [x] `apps/mobile/test/app/database/schema_test.dart` - schema version 1; tables match the saved v1 dump (`SchemaVerifier`); all seven tables exist
- [x] `apps/mobile/test/features/library/data/library_repository_test.dart` - stores a scan and reports counts; updates and missing on rescan; a failed scan keeps the library; permission failure passes through; database errors become `DatabaseFailure` with nothing written
- [x] `apps/mobile/test/features/library/application/library_access_controller_test.dart` - explanation only the first time; granted, unsupported, permanently denied; Allow requests and remembers; a dialog denial leads to denied; Not now asks nothing; permanent denial kept across plain status checks; Open settings; access granted in settings noticed on app resume; revoked access noticed
- [x] `apps/mobile/test/features/library/application/library_sync_controller_test.dart` - scans at start when granted; waits for access, then scans; never two scans at once; failure keeps the last result and the library; a permission failure re-checks access; recovers after a failure
- [x] `apps/mobile/test/features/library/presentation/library_screen_test.dart` - explanation first; Allow → scan → list; Not now → Grant access → system; permanent denial → Open settings; return from settings starts the scan; failing permission check → Try again; iOS state with no request or scan; list with count, Ethiopic text, file-name title, Unknown artist, voice note left out; scan at app start on Home; progress during the first scan; No music found; failed first scan → Try again; failed rescan keeps the list and shows a snackbar; light and dark palettes at 1.3× on a 320 dp phone with no overflow
- [x] `apps/mobile/test/shared/widgets/empty_state_test.dart` - custom icon and secondary button (≥ 44 px), no secondary button without a callback
- [x] `apps/mobile/test/helpers/fake_library.dart` - fakes and the in-memory database used above

### Acceptance Criteria Validation

Story 001: scanner spike
- ✅ **Emulator lists every test file with all fields**: 9/9 files from `tool/test_audio.sh` read through the Kotlin channel, Ethiopic tags intact
- ✅ **Decision recorded**: Kotlin channel; `on_audio_query` 2.9.0 fails on AGP 9.1 (walkthrough, `tech-stack.md`, construction log)
- ✅ **Only `LibraryScanner` in app code; iOS unsupported scanner; iOS build compiles**: `flutter build ios --simulator` and a run on the iOS simulator
- ✅ **Fake scanner in tests; platform errors mapped**: scanner tests

Story 002: database and identity
- ✅ **Schema v1 with seven tables**: schema test against the saved dump
- ✅ **Path first, then fingerprint; metadata updated**: reconcile and DAO tests
- ✅ **Moved file keeps its ID; new MediaStore IDs change nothing**: unit tests, and on the emulator ("1 moved, 0 added" after `mv`)
- ✅ **Missing marked, not deleted; returns with the same ID**: reconcile and DAO tests
- ✅ **Ambiguous fingerprint → new track**: two reconcile tests
- ✅ **Unit tests with Ethiopic titles; DAO and schema tested in memory**

Story 003: audio permission
- ✅ **Explanation before the dialog, shown once**: controller and screen tests; emulator
- ✅ **Granted → scan without restart; denied → Grant access; permanent → settings, return → scan**: tests and emulator (two denials → Open settings → grant in settings → back → list)
- ✅ **Permission per Android version; iOS no prompt**: permission service tests; iOS simulator
- ✅ **Fake covers all states including return from settings**

Story 004: scan and sync
- ✅ **Stored library at once; background scan at start; list updates**: tests; emulator (scan logged on launch with Home open)
- ✅ **Under 30 s, hidden folders and tracks excluded; deleted files disappear but stay stored**: DAO and repository tests; emulator (voice note absent)
- ✅ **Unknown artist localized; title from file name**: tests and emulator. "Unknown album" is used only when MediaStore reports no album (see Issues).
- ✅ **Failed scan: C07 Try again when empty, snackbar when stored; no double scans**: sync and screen tests
- ⏳ **1,000-track scan < 5 s on a mid-range phone (release)**: on the emulator (debug build), 1,010 files took 1,132 ms for the first sync and 884 ms for a repeat. The real-phone release check stays open.

### Issues Found

- `on_audio_query` doesn't build on AGP 9.1 → replaced by the Kotlin channel (planned fallback).
- `permission_handler` 13 needs compile SDK 37 → pinned to ^12.0.1.
- MediaStore reports the folder name as the album for untagged files, so those files group under their folder name, not "Unknown album". This is accepted: telling the two apart would mean reading every file's tags.
- Riverpod 3 pauses providers that are only read; tests listen while waiting for stream values.
- Closing a Drift database doesn't make later writes fail (it reopens), so the database-error test uses a failing DAO.

### Notes

- **Mutation checks**: removing subfolder hiding, the single-scan guard or the permanent-denial memory each makes a test fail. Removing the `toUtc()` read-back makes no test fail, because UTC dates already round-trip in text mode, so that line is only a safety net (its comment says so).
- **Manual checks**:
  - The permission dialog on Android 37 reads "Allow Zema to access music and audio on this device?".
  - After two denials, Android stops showing it and the app offers Open settings.
  - Revoking access while the app has stored tracks shows the grant state, not the old list.
- `tool/test_audio.sh --clean` removes the 1,010 test files from the emulator when no longer needed.
