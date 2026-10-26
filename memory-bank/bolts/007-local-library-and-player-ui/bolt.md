---
id: 007-local-library-and-player-ui
unit: 001-local-library-and-player-ui
intent: 002-local-library-and-player
type: simple-construction-bolt
status: complete
stories:
  - 014-favorites
  - 015-playlists
  - 016-add-songs-picker
  - 017-song-menu-and-add-to-playlist
created: 2026-10-24T19:23:00Z
started: 2026-10-26T08:28:15Z
completed: 2026-10-26T10:09:48Z
current_stage: null
stages_completed:
  - name: plan
    completed: 2026-10-26T08:30:17Z
    artifact: implementation-plan.md
  - name: implement
    completed: 2026-10-26T08:48:47Z
    artifact: implementation-walkthrough.md
  - name: test
    completed: 2026-10-26T10:09:48Z
    artifact: test-walkthrough.md
requires_bolts:
  - 006-local-library-and-player-ui
enables_bolts:
  - 008-local-library-and-player-ui
requires_units: []
blocks: false
complexity:
  avg_complexity: 2
  avg_uncertainty: 1
  max_dependencies: 2
  testing_scope: 2
---

# Bolt: 007-local-library-and-player-ui

## Overview

Let listeners organize: favorites, user playlists (create, rename, delete, reorder, remove), the add-songs picker, and the song menu with the add-to-playlist sheet on every track.

## Stories Included

- [x] **014-favorites**: S14 and hearts everywhere - Priority: Must
- [x] **015-playlists**: S15–S17 - Priority: Must
- [x] **016-add-songs-picker**: S18 - Priority: Must
- [x] **017-song-menu-and-add-to-playlist**: C03 and C04 - Priority: Must

## Bolt Type

**Type**: Simple Construction Bolt
**Definition**: `.specsmd/aidlc/templates/construction/bolt-types/simple-construction-bolt.md`

## Stages

- [x] **1. plan**: Complete → implementation-plan.md
- [x] **2. implement**: Complete → source code + implementation-walkthrough.md
- [x] **3. test**: Complete → tests + test-walkthrough.md

## Expected Outputs

- Favorites and Playlists tabs, playlist detail and dialogs
- `showSongMenu` used by all track lists and S08
- Drift DAO tests for favorites and playlists; widget tests for dialogs, undo and the menu

## Dependencies

### Requires
- 006-local-library-and-player-ui

### Enables
- 008-local-library-and-player-ui

## Success Criteria

- [x] All stories implemented
- [x] All acceptance criteria met
- [x] `flutter analyze` clean, `dart format` clean
- [ ] Tests passing locally (CI once a GitHub remote exists) (local: yes; CI: pending a GitHub remote)
- [x] Checked on the Android emulator (sending a shared file to another app needs an account; left for a real phone)
