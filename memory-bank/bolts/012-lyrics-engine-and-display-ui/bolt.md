---
id: 012-lyrics-engine-and-display-ui
unit: 001-lyrics-engine-and-display-ui
intent: 003-lyrics-engine-and-display
type: simple-construction-bolt
status: planned
stories:
  - 007-lyrics-models-and-play-order
  - 008-sync-engine
created: 2026-10-26T13:41:09Z
started: null
completed: null
current_stage: null
stages_completed: []
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

- [ ] **007-lyrics-models-and-play-order**: Lyrics models and play order - Priority: Must
- [ ] **008-sync-engine**: Sync engine - Priority: Must

## Bolt Type

**Type**: Simple Construction Bolt
**Definition**: `.specsmd/aidlc/templates/construction/bolt-types/simple-construction-bolt.md`

## Stages

- [ ] **1. plan**: Pending → implementation-plan.md
- [ ] **2. implement**: Pending → source code + implementation-walkthrough.md
- [ ] **3. test**: Pending → tests + test-walkthrough.md

## Expected Outputs

- `zema_core` lyrics module
- Unit tests incl. ±0.3 s boundaries

## Dependencies

### Requires
- 011-lyrics-engine-and-display-ui

### Enables
- 013-lyrics-engine-and-display-ui

## Success Criteria

- [ ] All stories implemented
- [ ] All acceptance criteria met
- [ ] `flutter analyze` clean, `dart format` clean
- [ ] Tests passing locally
- [ ] Checked on the Android emulator

## Notes

Small bolt (intent 003 keeps bolts to 1–2 stories so each finishes in one session).
