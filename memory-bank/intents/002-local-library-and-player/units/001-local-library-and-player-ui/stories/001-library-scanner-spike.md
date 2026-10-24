---
id: 001-library-scanner-spike
unit: 001-local-library-and-player-ui
intent: 002-local-library-and-player
status: draft
priority: must
created: 2026-10-24T20:15:00Z
assigned_bolt: 004-local-library-and-player-ui
implemented: false
---

# Story: 001-library-scanner-spike

## User Story

**As a** developer
**I want** to know which MediaStore scanner works on Flutter 3.47 before building on it
**So that** the rest of the intent doesn't rest on a plugin that won't build

## Acceptance Criteria

- [ ] **Given** an Android emulator (API 34) with generated test files in `/sdcard/Music`, `/sdcard/Download` and a folder with an Ethiopic name, **When** the spike runs, **Then** `on_audio_query` is tried first: it builds with the current Android Gradle Plugin and returns every test file with title, artist, album, duration, size, path and date added
- [ ] **Given** the plugin fails to build, crashes or misses fields, **When** the spike ends, **Then** a Kotlin `MethodChannel` (`com.zemaapp.zema/library`) querying `MediaStore.Audio.Media` replaces it, and the outcome is recorded in the bolt's implementation walkthrough and `standards/tech-stack.md`
- [ ] **Given** either outcome, **When** the app code uses the scanner, **Then** it only sees the Dart `LibraryScanner` interface (`scan()` → `List<ScannedAudio>`, `loadArtwork(id, size)` → bytes or null)
- [ ] **Given** iOS, **When** the scanner is created, **Then** an `UnsupportedLibraryScanner` is used and the iOS build still compiles
- [ ] **Given** tests, **When** run, **Then** a `FakeLibraryScanner` returns fixture entries (Latin and Ethiopic) and the platform implementation maps `PlatformException` to a `PermissionFailure` or `ScanFailure`

## Technical Notes

- Create the emulator from the installed SDK system image (`avdmanager`), generate test MP3s with `ffmpeg` (sine tones, ID3 tags, a 10 s "voice note", a file without tags) and push them with `adb push`; trigger a media scan.
- Kotlin fallback reference: old `MusicRepository.kt` (`docs/flutter-build-notes.md`). Album art via `ContentResolver.loadThumbnail` (API 29+).
- Keep the spike time-boxed: decide within the bolt's implement stage and report before continuing.

## Dependencies

### Requires
- None (first story of the intent)

### Enables
- 002-library-database
- 004-library-scan-and-sync

## Edge Cases

| Scenario | Expected Behavior |
|----------|-------------------|
| Test file without ID3 tags | Title from file name; artist/album unknown |
| Path not readable (Android 10+ scoped storage) | Use `RELATIVE_PATH` + display name to build the folder path |

## Out of Scope

- Scanning on iOS
- Album-art colors
