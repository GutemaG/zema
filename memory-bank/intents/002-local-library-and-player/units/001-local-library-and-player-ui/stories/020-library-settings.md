---
id: 020-library-settings
unit: 001-local-library-and-player-ui
intent: 002-local-library-and-player
status: draft
priority: must
created: 2026-10-24T19:22:00Z
assigned_bolt: 008-local-library-and-player-ui
implemented: false
---

# Story: 020-library-settings

## User Story

**As a** listener
**I want** to control what Zema treats as music
**So that** voice notes and unwanted folders stay out of my library

## Acceptance Criteria

- [ ] **Given** Settings, **When** shown, **Then** a Library section sits between General and About
- [ ] **Given** Hidden folders / Hidden songs, **When** opened, **Then** they list hidden items with an Unhide action each; unhidden items come back everywhere
- [ ] **Given** Rescan library, **When** tapped, **Then** a progress indicator shows and then the number of tracks found
- [ ] **Given** "Ignore audio shorter than", **When** set to off, 10, 30 or 60 s (default 30 s), **Then** the library updates without a rescan and the value persists
- [ ] **Given** no access, **When** Rescan is tapped, **Then** the permission flow (003) starts

## Technical Notes

- Minimum duration in `SettingsRepository` (key `minTrackSeconds`); filtering in the Drift query, so no rescan is needed.

## Dependencies

### Requires
- 004-library-scan-and-sync
- 011-folders
- 017-song-menu-and-add-to-playlist

### Enables
- None

## Out of Scope

- Included folders list (only exclusions)
- Offline lyrics storage (P2)
