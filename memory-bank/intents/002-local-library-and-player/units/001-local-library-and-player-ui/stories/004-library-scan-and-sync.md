---
id: 004-library-scan-and-sync
unit: 001-local-library-and-player-ui
intent: 002-local-library-and-player
status: complete
priority: must
created: 2026-10-24T19:22:00Z
assigned_bolt: 004-local-library-and-player-ui
implemented: true
---

# Story: 004-library-scan-and-sync

## User Story

**As a** listener
**I want** the library to show my songs quickly and stay up to date
**So that** I see new downloads without doing anything

## Acceptance Criteria

- [ ] **Given** access is granted, **When** the app starts, **Then** the stored library shows immediately and a background scan reconciles it; lists update when it finishes
- [ ] **Given** a scan, **When** it finishes, **Then** audio shorter than the minimum duration (default 30 s) is excluded
- [ ] **Given** a hidden folder or hidden track, **When** any list, search, album, artist, auto playlist or Play / Shuffle is built, **Then** those tracks are left out
- [ ] **Given** a track deleted from the phone, **When** the scan finishes, **Then** it disappears from all lists; its playlist and favorite entries stay stored but hidden
- [ ] **Given** missing metadata, **When** shown, **Then** "Unknown artist" / "Unknown album" (localized) are used and the title falls back to the file name
- [ ] **Given** a failed scan, **When** it ends, **Then** C07 error with "Try again" shows on an empty library, or a snackbar when a stored library exists
- [ ] **Given** a scan already running, **When** another is requested, **Then** it is not started twice
- [ ] **Given** 1,000 tracks, **When** scanned on a mid-range phone in release mode, **Then** it finishes in under 5 s (measured and logged at INFO with count and time)

## Technical Notes

- `LibraryRepository.sync()` wraps the scan and the reconciliation in one Drift transaction; exposes `libraryTracksProvider` as a stream from Drift.
- Folder = the parent directory of the path; albums group by album + album artist (or artist); artists by artist.
- Generate a 1,000-file fixture for the timing check on the emulator (indicative only; the real target is a mid-range phone).

## Dependencies

### Requires
- 001-library-scanner-spike
- 002-library-database
- 003-audio-permission

### Enables
- 005-library-tab-and-tracks
- 011-folders
- 012-albums
- 013-artists

## Edge Cases

| Scenario | Expected Behavior |
|----------|-------------------|
| Two files with the same path differing in case | Treated as different files |
| Scan interrupted by the app going to background | Transaction is not committed; next start rescans |

## Out of Scope

- Watching MediaStore for live changes (rescan on start and on demand is enough)
