---
id: 009-lyrics-engine-and-display-ui
unit: 001-lyrics-engine-and-display-ui
intent: 003-lyrics-engine-and-display
type: simple-construction-bolt
status: complete
stories:
  - 001-home-header-and-quick-actions
  - 002-home-continue-and-recent-rows
created: 2026-10-26T13:41:09Z
started: 2026-10-26T13:45:42Z
completed: 2026-10-26T14:28:23Z
current_stage: null
stages_completed:
  - name: plan
    completed: 2026-10-26T13:47:57Z
    artifact: implementation-plan.md
  - name: implement
    completed: 2026-10-26T13:53:06Z
    artifact: implementation-walkthrough.md
  - name: test
    completed: 2026-10-26T14:28:23Z
    artifact: test-walkthrough.md
requires_bolts: []
enables_bolts:
  - 010-lyrics-engine-and-display-ui
requires_units: []
blocks: false
complexity:
  avg_complexity: 1
  avg_uncertainty: 1
  max_dependencies: 2
  testing_scope: 2
---

# Bolt: 009-lyrics-engine-and-display-ui

## Overview

Turn the Home tab into a working screen: header, quick actions, continue listening, recently played and playlists rows.

## Stories Included

- [x] **001-home-header-and-quick-actions**: Home header and quick actions - Priority: Must
- [x] **002-home-continue-and-recent-rows**: Home continue listening and recent rows - Priority: Must

## Bolt Type

**Type**: Simple Construction Bolt
**Definition**: `.specsmd/aidlc/templates/construction/bolt-types/simple-construction-bolt.md`

## Stages

- [x] **1. plan**: Complete → implementation-plan.md
- [x] **2. implement**: Complete → source code + implementation-walkthrough.md
- [x] **3. test**: Complete → tests + test-walkthrough.md

## Expected Outputs

- Home screen replacing "Coming soon"
- Widget tests incl. 1.3× and both themes

## Dependencies

### Requires
- None in this intent (intent 002 complete)

### Enables
- 010-lyrics-engine-and-display-ui

## Success Criteria

- [x] All stories implemented
- [x] All acceptance criteria met (Home's < 1 s start needs a release build on a phone; see test-walkthrough.md)
- [x] `flutter analyze` clean, `dart format` clean
- [x] Tests passing locally (CI: pending a GitHub remote)
- [x] Checked on the Android emulator

## Notes

Small bolt (intent 003 keeps bolts to 1–2 stories so each finishes in one session).
