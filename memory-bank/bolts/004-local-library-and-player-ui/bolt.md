---
id: 004-local-library-and-player-ui
unit: 001-local-library-and-player-ui
intent: 002-local-library-and-player
type: simple-construction-bolt
status: planned
stories:
  - 001-library-scanner-spike
  - 002-library-database
  - 003-audio-permission
  - 004-library-scan-and-sync
created: 2026-10-24T20:20:00Z
started: null
completed: null
current_stage: null
stages_completed: []
requires_bolts: []
enables_bolts:
  - 005-local-library-and-player-ui
requires_units:
  - 001-app-foundation-ui
blocks: false
complexity:
  avg_complexity: 2
  avg_uncertainty: 3
  max_dependencies: 3
  testing_scope: 2
---

# Bolt: 004-local-library-and-player-ui

## Overview

Prove the MediaStore scanner on an Android emulator (on_audio_query or a Kotlin fallback), create the first Drift database with stable track identity, ask for audio access, and scan and sync the library. No library UI beyond the permission and scan states.

## Stories Included

- [ ] **001-library-scanner-spike**: Scanner spike, `LibraryScanner` interface, emulator + test files - Priority: Must
- [ ] **002-library-database**: Drift schema v1, `Track` + fingerprint + reconciliation in `zema_core` - Priority: Must
- [ ] **003-audio-permission**: Explanation, request, denied / permanently denied, iOS state - Priority: Must
- [ ] **004-library-scan-and-sync**: Sync on start and on demand, min duration, hidden items, missing files - Priority: Must

## Bolt Type

**Type**: Simple Construction Bolt
**Definition**: `.specsmd/aidlc/templates/construction/bolt-types/simple-construction-bolt.md`

## Stages

- [ ] **1. plan**: Pending → implementation-plan.md
- [ ] **2. implement**: Pending → source code + implementation-walkthrough.md
- [ ] **3. test**: Pending → tests + test-walkthrough.md

## Expected Outputs

- Android emulator (API 34) with generated test audio
- `apps/mobile/lib/features/library/data/` (scanner, repository), `lib/app/database/` (Drift)
- `packages/zema_core/lib/src/library/` (models, reconciliation) with unit tests
- Permission flow and C07 states in the Library tab
- Drift DAO + migration-harness tests; scanner decision recorded in `standards/tech-stack.md`

## Dependencies

### Requires
- Intent 001 complete (`001-app-foundation-ui`)

### Enables
- 005-local-library-and-player-ui

## Success Criteria

- [ ] All stories implemented
- [ ] All acceptance criteria met
- [ ] `flutter analyze` clean, `dart format` clean
- [ ] Tests passing locally (CI once a GitHub remote exists)
- [ ] Checked on the Android emulator

## Notes

High uncertainty (story 001): the implement stage starts with the spike and reports the scanner decision before building the rest. Decide whether generated Drift code is committed (like the l10n output) in the plan stage.
