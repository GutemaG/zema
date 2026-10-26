---
id: 006-local-library-and-player-ui
unit: 001-local-library-and-player-ui
intent: 002-local-library-and-player
type: simple-construction-bolt
status: complete
stories:
  - 009-queue-sheet
  - 010-sleep-timer
  - 011-folders
  - 012-albums
  - 013-artists
created: 2026-10-24T19:23:00Z
started: 2026-10-26T07:27:17Z
completed: 2026-10-26T08:21:49Z
current_stage: null
stages_completed:
  - name: plan
    completed: 2026-10-26T07:28:43Z
    artifact: implementation-plan.md
  - name: implement
    completed: 2026-10-26T08:07:29Z
    artifact: implementation-walkthrough.md
  - name: test
    completed: 2026-10-26T08:21:49Z
    artifact: test-walkthrough.md
requires_bolts:
  - 005-local-library-and-player-ui
enables_bolts:
  - 007-local-library-and-player-ui
requires_units: []
blocks: false
complexity:
  avg_complexity: 2
  avg_uncertainty: 1
  max_dependencies: 2
  testing_scope: 2
---

# Bolt: 006-local-library-and-player-ui

## Overview

Finish the player sheets (queue and sleep timer) and add the browse tabs: Folders with contents and hide, Albums with detail, Artists with detail.

## Stories Included

- [x] **009-queue-sheet**: C02: reorder, remove with undo, clear - Priority: Must
- [x] **010-sleep-timer**: C05: presets, end of song, custom, fade out - Priority: Must
- [x] **011-folders**: S11 / S11a with breadcrumb and hide - Priority: Must
- [x] **012-albums**: S12 / S12a - Priority: Must
- [x] **013-artists**: S13 / S13a (Should) - Priority: Should

## Bolt Type

**Type**: Simple Construction Bolt
**Definition**: `.specsmd/aidlc/templates/construction/bolt-types/simple-construction-bolt.md`

## Stages

- [x] **1. plan**: Complete → implementation-plan.md
- [x] **2. implement**: Complete → source code + implementation-walkthrough.md
- [x] **3. test**: Complete → tests + test-walkthrough.md

## Expected Outputs

- Queue and sleep timer sheets wired into S08
- Folders, Albums, Artists tabs and detail routes
- Fake-clock tests for the timer; widget tests for each tab in empty and data states

## Dependencies

### Requires
- 005-local-library-and-player-ui

### Enables
- 007-local-library-and-player-ui

## Success Criteria

- [x] All stories implemented
- [x] All acceptance criteria met
- [x] `flutter analyze` clean, `dart format` clean
- [ ] Tests passing locally (CI once a GitHub remote exists) (local: yes; CI: pending a GitHub remote)
- [x] Checked on the Android emulator (queue Undo, button color, short breadcrumb and Artists covered by tests only)

## Notes

Artists is Should: if the bolt runs long, it can move to bolt 008.
