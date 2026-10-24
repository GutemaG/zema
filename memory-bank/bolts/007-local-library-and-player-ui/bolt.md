---
id: 007-local-library-and-player-ui
unit: 001-local-library-and-player-ui
intent: 002-local-library-and-player
type: simple-construction-bolt
status: planned
stories:
  - 014-favorites
  - 015-playlists
  - 016-add-songs-picker
  - 017-song-menu-and-add-to-playlist
created: 2026-10-24T20:20:00Z
started: null
completed: null
current_stage: null
stages_completed: []
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

- [ ] **014-favorites**: S14 and hearts everywhere - Priority: Must
- [ ] **015-playlists**: S15–S17 - Priority: Must
- [ ] **016-add-songs-picker**: S18 - Priority: Must
- [ ] **017-song-menu-and-add-to-playlist**: C03 and C04 - Priority: Must

## Bolt Type

**Type**: Simple Construction Bolt
**Definition**: `.specsmd/aidlc/templates/construction/bolt-types/simple-construction-bolt.md`

## Stages

- [ ] **1. plan**: Pending → implementation-plan.md
- [ ] **2. implement**: Pending → source code + implementation-walkthrough.md
- [ ] **3. test**: Pending → tests + test-walkthrough.md

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

- [ ] All stories implemented
- [ ] All acceptance criteria met
- [ ] `flutter analyze` clean, `dart format` clean
- [ ] Tests passing locally (CI once a GitHub remote exists)
- [ ] Checked on the Android emulator
