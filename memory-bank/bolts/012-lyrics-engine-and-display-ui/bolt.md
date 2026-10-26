---
id: 012-lyrics-engine-and-display-ui
unit: 001-lyrics-engine-and-display-ui
intent: 003-lyrics-engine-and-display
type: simple-construction-bolt
status: complete
stories:
  - 007-lyrics-models-and-play-order
  - 008-sync-engine
created: 2026-10-26T13:41:09Z
started: 2026-10-26T17:27:14Z
completed: 2026-10-26T17:35:18Z
current_stage: null
stages_completed:
  - name: plan
    completed: 2026-10-26T17:29:32Z
    artifact: implementation-plan.md
  - name: implement
    completed: 2026-10-26T17:30:44Z
    artifact: implementation-walkthrough.md
  - name: test
    completed: 2026-10-26T17:35:18Z
    artifact: test-walkthrough.md
requires_bolts:
  - 011-lyrics-engine-and-display-ui
enables_bolts:
  - 013-lyrics-engine-and-display-ui
requires_units: []
blocks: false
complexity:
  avg_complexity: 2
  avg_uncertainty: 1
  max_dependencies: 2
  testing_scope: 2
---

# Bolt: 012-lyrics-engine-and-display-ui

## Overview

Lyrics models, play-order expansion and the sync engine in `zema_core`.

## Stories Included

- [x] **007-lyrics-models-and-play-order**: Lyrics models and play order - Priority: Must
- [x] **008-sync-engine**: Sync engine - Priority: Must

## Bolt Type

**Type**: Simple Construction Bolt
**Definition**: `.specsmd/aidlc/templates/construction/bolt-types/simple-construction-bolt.md`

## Stages

- [x] **1. plan**: Complete → implementation-plan.md
- [x] **2. implement**: Complete → source code + implementation-walkthrough.md
- [x] **3. test**: Complete → tests + test-walkthrough.md

## Expected Outputs

- `zema_core` lyrics module
- Unit tests incl. ±0.3 s boundaries

## Dependencies

### Requires
- 011-lyrics-engine-and-display-ui

### Enables
- 013-lyrics-engine-and-display-ui

## Success Criteria

- [x] All stories implemented
- [x] All acceptance criteria met
- [x] `flutter analyze` clean, `dart format` clean
- [x] Tests passing locally (CI: pending a GitHub remote)
- [x] Checked on the Android emulator (not applicable: no UI uses it until bolt 015)

## Notes

Small bolt (intent 003 keeps bolts to 1–2 stories so each finishes in one session).
