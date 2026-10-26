---
id: 015-lyrics-engine-and-display-ui
unit: 001-lyrics-engine-and-display-ui
intent: 003-lyrics-engine-and-display
type: simple-construction-bolt
status: complete
stories:
  - 012-lyrics-view-now-playing
  - 013-lyrics-scroll-and-offset
created: 2026-10-26T13:41:09Z
started: 2026-10-26T19:32:18Z
completed: 2026-10-26T19:58:12Z
current_stage: null
stages_completed:
  - name: plan
    completed: 2026-10-26T19:50:28Z
    artifact: implementation-plan.md
  - name: implement
    completed: 2026-10-26T19:50:28Z
    artifact: implementation-walkthrough.md
  - name: test
    completed: 2026-10-26T19:58:12Z
    artifact: test-walkthrough.md
requires_bolts:
  - 014-lyrics-engine-and-display-ui
enables_bolts:
  - 016-lyrics-engine-and-display-ui
requires_units: []
blocks: false
complexity:
  avg_complexity: 2
  avg_uncertainty: 1
  max_dependencies: 2
  testing_scope: 2
---

# Bolt: 015-lyrics-engine-and-display-ui

## Overview

The lyrics view (C06) on Now Playing with highlight, seek, auto-scroll and sync offset.

## Stories Included

- [x] **012-lyrics-view-now-playing**: Lyrics view on Now Playing - Priority: Must
- [x] **013-lyrics-scroll-and-offset**: Lyrics auto-scroll and sync offset - Priority: Must

## Bolt Type

**Type**: Simple Construction Bolt
**Definition**: `.specsmd/aidlc/templates/construction/bolt-types/simple-construction-bolt.md`

## Stages

- [x] **1. plan**: Complete → implementation-plan.md
- [x] **2. implement**: Complete → source code + implementation-walkthrough.md
- [x] **3. test**: Complete → tests + test-walkthrough.md

## Expected Outputs

- C06 widget
- Now Playing lyrics mode

## Dependencies

### Requires
- 014-lyrics-engine-and-display-ui

### Enables
- 016-lyrics-engine-and-display-ui

## Success Criteria

- [x] All stories implemented
- [x] All acceptance criteria met
- [x] `flutter analyze` clean, `dart format` clean
- [x] Tests passing locally
- [x] Checked on the Android emulator

## Notes

Small bolt (intent 003 keeps bolts to 1–2 stories so each finishes in one session).
