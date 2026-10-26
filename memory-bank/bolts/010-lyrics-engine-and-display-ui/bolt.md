---
id: 010-lyrics-engine-and-display-ui
unit: 001-lyrics-engine-and-display-ui
intent: 003-lyrics-engine-and-display
type: simple-construction-bolt
status: planned
stories:
  - 003-ethiopic-normalization
  - 004-transliteration-matching
created: 2026-10-26T13:41:09Z
started: null
completed: null
current_stage: null
stages_completed: []
requires_bolts:
  - 009-lyrics-engine-and-display-ui
enables_bolts:
  - 011-lyrics-engine-and-display-ui
requires_units: []
blocks: false
complexity:
  avg_complexity: 2
  avg_uncertainty: 2
  max_dependencies: 2
  testing_scope: 2
---

# Bolt: 010-lyrics-engine-and-display-ui

## Overview

Ethiopic normalization and transliteration matching in `zema_core`, as data tables portable to 004.

## Stories Included

- [ ] **003-ethiopic-normalization**: Ethiopic search normalization - Priority: Must
- [ ] **004-transliteration-matching**: Transliteration matching - Priority: Must

## Bolt Type

**Type**: Simple Construction Bolt
**Definition**: `.specsmd/aidlc/templates/construction/bolt-types/simple-construction-bolt.md`

## Stages

- [ ] **1. plan**: Pending → implementation-plan.md
- [ ] **2. implement**: Pending → source code + implementation-walkthrough.md
- [ ] **3. test**: Pending → tests + test-walkthrough.md

## Expected Outputs

- `zema_core` search module with rule tables
- Unit tests of query/target pairs

## Dependencies

### Requires
- 009-lyrics-engine-and-display-ui

### Enables
- 011-lyrics-engine-and-display-ui

## Success Criteria

- [ ] All stories implemented
- [ ] All acceptance criteria met
- [ ] `flutter analyze` clean, `dart format` clean
- [ ] Tests passing locally
- [ ] Checked on the Android emulator

## Notes

Small bolt (intent 003 keeps bolts to 1–2 stories so each finishes in one session).
