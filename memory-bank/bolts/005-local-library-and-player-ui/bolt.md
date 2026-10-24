---
id: 005-local-library-and-player-ui
unit: 001-local-library-and-player-ui
intent: 002-local-library-and-player
type: simple-construction-bolt
status: complete
stories:
  - 005-library-tab-and-tracks
  - 006-playback-engine
  - 007-mini-player-and-now-playing
  - 008-media-notification
created: 2026-10-24T19:23:00Z
started: 2026-10-24T20:04:34Z
completed: 2026-10-24T21:20:18Z
current_stage: null
stages_completed:
  - name: plan
    completed: 2026-10-24T20:07:33Z
    artifact: implementation-plan.md
  - name: implement
    completed: 2026-10-24T20:54:50Z
    artifact: implementation-walkthrough.md
  - name: test
    completed: 2026-10-24T21:20:18Z
    artifact: test-walkthrough.md
requires_bolts:
  - 004-local-library-and-player-ui
enables_bolts:
  - 006-local-library-and-player-ui
requires_units: []
blocks: false
complexity:
  avg_complexity: 2
  avg_uncertainty: 2
  max_dependencies: 3
  testing_scope: 3
---

# Bolt: 005-local-library-and-player-ui

## Overview

Play a song end to end: Library tab with Tracks (search, sort, fast-scroll), the playback engine with shuffle and repeat, the mini player and Now Playing, and background playback with the media notification, lock screen and headset buttons.

## Stories Included

- [x] **005-library-tab-and-tracks**: Library top tabs and Tracks (S10) - Priority: Must
- [x] **006-playback-engine**: just_audio + audio_service, queue logic, restore last queue - Priority: Must
- [x] **007-mini-player-and-now-playing**: C01 and S08 (controls only) - Priority: Must
- [x] **008-media-notification**: C08, headset buttons, audio focus, unplug - Priority: Must

## Bolt Type

**Type**: Simple Construction Bolt
**Definition**: `.specsmd/aidlc/templates/construction/bolt-types/simple-construction-bolt.md`

## Stages

- [x] **1. plan**: Complete → implementation-plan.md
- [x] **2. implement**: Complete → source code + implementation-walkthrough.md
- [x] **3. test**: Complete → tests + test-walkthrough.md

## Expected Outputs

- `lib/features/library/presentation/` (Library tab, Tracks)
- `lib/features/player/` (handler, queue, providers, S08)
- `lib/shared/widgets/` (TrackRow, TrackArt, mini player)
- Manifest service config; unit tests for queue logic; widget tests for Tracks, C01, S08
- Emulator check: play, background, notification controls

## Dependencies

### Requires
- 004-local-library-and-player-ui

### Enables
- 006-local-library-and-player-ui

## Success Criteria

- [x] All stories implemented
- [x] All acceptance criteria met (real-phone scrolling and 30-min battery checks open)
- [x] `flutter analyze` clean, `dart format` clean
- [ ] Tests passing locally (CI once a GitHub remote exists) (local: yes; CI: pending a GitHub remote)
- [x] Checked on the Android emulator

## Notes

The 30-minute screen-off check needs a real phone; record it as open if none is available.
