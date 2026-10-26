---
id: 014-lyrics-engine-and-display-ui
unit: 001-lyrics-engine-and-display-ui
intent: 003-lyrics-engine-and-display
type: simple-construction-bolt
status: planned
stories:
  - 011-track-song-linking
created: 2026-10-26T13:41:09Z
started: null
completed: null
current_stage: null
stages_completed: []
requires_bolts:
  - 013-lyrics-engine-and-display-ui
enables_bolts:
  - 015-lyrics-engine-and-display-ui
requires_units: []
blocks: false
complexity:
  avg_complexity: 2
  avg_uncertainty: 2
  max_dependencies: 2
  testing_scope: 2
---

# Bolt: 014-lyrics-engine-and-display-ui

## Overview

Automatic and manual track-to-song links in Drift schema v2.

## Stories Included

- [ ] **011-track-song-linking**: Link local tracks to songs - Priority: Must

## Bolt Type

**Type**: Simple Construction Bolt
**Definition**: `.specsmd/aidlc/templates/construction/bolt-types/simple-construction-bolt.md`

## Stages

- [ ] **1. plan**: Pending → implementation-plan.md
- [ ] **2. implement**: Pending → source code + implementation-walkthrough.md
- [ ] **3. test**: Pending → tests + test-walkthrough.md

## Expected Outputs

- Link table + migration test
- Match lyrics / Unlink in the song menu

## Dependencies

### Requires
- 013-lyrics-engine-and-display-ui

### Enables
- 015-lyrics-engine-and-display-ui

## Success Criteria

- [ ] All stories implemented
- [ ] All acceptance criteria met
- [ ] `flutter analyze` clean, `dart format` clean
- [ ] Tests passing locally
- [ ] Checked on the Android emulator

## Notes

Small bolt (intent 003 keeps bolts to 1–2 stories so each finishes in one session).
