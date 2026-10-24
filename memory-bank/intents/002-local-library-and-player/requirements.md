---
intent: 002-local-library-and-player
phase: inception
status: draft
created: 2026-10-23T22:16:40Z
updated: 2026-10-23T22:16:40Z
---

# Requirements: Local Library and Player

> Source: `docs/roadmap.md` Stage 2 · screens/components: `docs/screens.md` S08, S10–S18,
> S28, C01–C05, C07, C08 · Complexity ★★☆☆☆ · No backend, no native code.

## Intent Overview

A complete offline music player for the phone's audio files: library browsing (tracks,
folders, albums, artists, favorites, playlists) and background playback with system
controls.

## Business Goals

| Goal | Success Metric | Priority |
|------|----------------|----------|
| Fast library on mid-range phones | 1,000-track scan < 5 s; lists scroll smoothly | Must |
| Reliable background playback | Plays 30+ min with screen off; notification controls work | Must |
| Persistent user library | Favorites and playlists survive restart | Must |

---

## Functional Requirements

### FR-1: Audio permission
- **Description**: Request `READ_MEDIA_AUDIO` (older Android: storage) with a clear explanation and a "grant later" path.
- **Acceptance Criteria**: Denial shows C07 empty state with a grant action; granting triggers a scan.
- **Priority**: Must

### FR-2: Library scan
- **Description**: Scan MediaStore via `on_audio_query`; derive folders from file paths; ignore audio shorter than N s (default 30 s); support hidden folders; manual rescan.
- **Acceptance Criteria**: Voice notes < 30 s excluded; hidden folders excluded everywhere.
- **Priority**: Must

### FR-3: Tracks (S10)
- **Description**: All tracks with count, search-as-you-type filter, sort (title/artist/album/date added/duration, asc/desc), alphabet fast-scroll, multi-select (add to playlist, add to queue, favorite, hide).
- **Priority**: Must

### FR-4: Folders (S11 / S11a)
- **Description**: Folders with audio, song count and path; folder contents with breadcrumb, subfolders first, Play all / Shuffle; hide/unhide.
- **Priority**: Must

### FR-5: Albums (S12 / S12a)
- **Description**: Album grid sorted by name/artist/year; album detail with cover, metadata, numbered track list, Play / Shuffle.
- **Priority**: Must

### FR-6: Artists (S13 / S13a)
- **Description**: Artist list with avatar and song count; artist detail with albums and songs.
- **Priority**: Should (P2 in screens.md, in stage 2 scope)

### FR-7: Favorites (S14)
- **Description**: Favorited songs, search, Play / Shuffle, remove with undo.
- **Priority**: Must

### FR-8: Playlists (S15–S18)
- **Description**: Create/rename (unique name, optional description), delete with confirmation, reorder by drag, remove by swipe with undo, add-songs picker with already-added marks. Auto playlists: Recently added, Most played, Recently played.
- **Priority**: Must

### FR-9: Playback engine
- **Description**: `just_audio` + `audio_service`; background playback; shuffle; repeat off/all/one; queue (C02) reorder/remove/clear; sleep timer (C05: 15/30/45/60 min, end of song, custom).
- **Priority**: Must

### FR-10: Now Playing (S08, controls only) and mini player (C01)
- **Description**: Seek bar and transport controls; lyrics area shows "No lyrics yet". Mini player above bottom nav; tap → S08.
- **Priority**: Must

### FR-11: Song menu (C03) and add-to-playlist sheet (C04)
- **Description**: Play next, add to queue, add to playlist, favorite, go to album/artist, hide, share (lyrics/edit actions disabled until later stages).
- **Priority**: Must

### FR-12: Media notification & lock screen (C08)
- **Priority**: Must

### FR-13: Play history and counts
- **Description**: Stored in Drift; feed Most played / Recently played.
- **Priority**: Must

### FR-14: Settings — Library and Playback sections (S28)
- **Description**: Included/excluded folders, rescan, min duration; sleep timer default, gapless, pause on headphone unplug, audio focus behavior.
- **Priority**: Must

---

## Non-Functional Requirements

### Performance
| Requirement | Metric | Target |
|-------------|--------|--------|
| Library scan | 1,000 tracks, mid-range phone | < 5 s |
| List scrolling | Frame rate | 60 fps |

### Reliability
| Requirement | Metric | Target |
|-------------|--------|--------|
| Background playback | Screen off, battery saver on | ≥ 30 min uninterrupted |
| Persistence | Favorites/playlists after restart | 100% retained |

---

## Constraints

### Technical Constraints

**Project-wide standards**: Required standards will be loaded from memory-bank standards folder by Construction Agent

**Intent-specific constraints**:
- First Drift schema; design migrations from the start (later stages add lyrics cache and matches).
- Track identity must be stable across rescans (needed for playlists and later backup re-linking in 005).

### Business Constraints
- **Out of scope:** lyrics, accounts, cloud, edit song info (S09).

---

## Assumptions

| Assumption | Risk if Invalid | Mitigation |
|------------|-----------------|------------|
| `on_audio_query` works on target Android versions | Scan fails/incomplete | Fallback: small Kotlin MediaStore channel (old `MusicRepository.kt` as reference) |
| OEM battery savers allow `audio_service` foreground service | Playback killed | Test on Tecno/Infinix/Samsung A; document battery settings |

---

## Open Questions

| Question | Owner | Due Date | Resolution |
|----------|-------|----------|------------|
| Stable track ID: MediaStore ID vs path+size+duration hash? | Construction | Before Drift schema | Pending |
| Album-art palette for S08 background now or in 003? | Product owner | Requirements review | Pending |
