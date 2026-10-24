---
id: 006-local-library-and-player-ui
unit: 001-local-library-and-player-ui
intent: 002-local-library-and-player
type: simple-construction-bolt
status: planned
stories:
  - 009-queue-sheet
  - 010-sleep-timer
  - 011-folders
  - 012-albums
  - 013-artists
created: 2026-10-24T20:20:00Z
started: null
completed: null
current_stage: null
stages_completed: []
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

- [ ] **009-queue-sheet**: C02: reorder, remove with undo, clear - Priority: Must
- [ ] **010-sleep-timer**: C05: presets, end of song, custom, fade out - Priority: Must
- [ ] **011-folders**: S11 / S11a with breadcrumb and hide - Priority: Must
- [ ] **012-albums**: S12 / S12a - Priority: Must
- [ ] **013-artists**: S13 / S13a (Should) - Priority: Should

## Bolt Type

**Type**: Simple Construction Bolt
**Definition**: `.specsmd/aidlc/templates/construction/bolt-types/simple-construction-bolt.md`

## Stages

- [ ] **1. plan**: Pending → implementation-plan.md
- [ ] **2. implement**: Pending → source code + implementation-walkthrough.md
- [ ] **3. test**: Pending → tests + test-walkthrough.md

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

- [ ] All stories implemented
- [ ] All acceptance criteria met
- [ ] `flutter analyze` clean, `dart format` clean
- [ ] Tests passing locally (CI once a GitHub remote exists)
- [ ] Checked on the Android emulator

## Notes

Artists is Should: if the bolt runs long, it can move to bolt 008.
