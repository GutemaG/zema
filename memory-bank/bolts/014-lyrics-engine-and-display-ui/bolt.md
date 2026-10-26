---
id: 014-lyrics-engine-and-display-ui
unit: 001-lyrics-engine-and-display-ui
intent: 003-lyrics-engine-and-display
type: simple-construction-bolt
status: complete
stories:
  - 011-track-song-linking
created: 2026-10-26T13:41:09Z
started: 2026-10-26T17:43:44Z
completed: 2026-10-26T19:31:20Z
current_stage: null
stages_completed:
  - name: plan
    completed: 2026-10-26T17:44:38Z
    artifact: implementation-plan.md
  - name: implement
    completed: 2026-10-26T17:49:24Z
    artifact: implementation-walkthrough.md
  - name: test
    completed: 2026-10-26T19:31:20Z
    artifact: test-walkthrough.md
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

- [x] **011-track-song-linking**: Link local tracks to songs - Priority: Must

## Bolt Type

**Type**: Simple Construction Bolt
**Definition**: `.specsmd/aidlc/templates/construction/bolt-types/simple-construction-bolt.md`

## Stages

- [x] **1. plan**: Complete → implementation-plan.md
- [x] **2. implement**: Complete → source code + implementation-walkthrough.md
- [x] **3. test**: Complete → tests + test-walkthrough.md

## Expected Outputs

- Link table + migration test
- Match lyrics / Unlink in the song menu

## Dependencies

### Requires
- 013-lyrics-engine-and-display-ui

### Enables
- 015-lyrics-engine-and-display-ui

## Success Criteria

- [x] All stories implemented
- [x] All acceptance criteria met
- [x] `flutter analyze` clean, `dart format` clean
- [x] Tests passing locally
- [x] Checked on the Android emulator

## Notes

Small bolt (intent 003 keeps bolts to 1–2 stories so each finishes in one session).
