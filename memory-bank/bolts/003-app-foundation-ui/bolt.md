---
id: 003-app-foundation-ui
unit: 001-app-foundation-ui
intent: 001-app-foundation
type: simple-construction-bolt
status: planned
stories:
  - 008-settings-screen
  - 009-switch-palette
  - 010-switch-language
created: 2026-10-23T22:22:46Z
started: null
completed: null
current_stage: null
stages_completed: []

requires_bolts: [002-app-foundation-ui]
enables_bolts: []
requires_units: []
blocks: false

complexity:
  avg_complexity: 2
  avg_uncertainty: 1
  max_dependencies: 2
  testing_scope: 3
---

# Bolt: 003-app-foundation-ui

## Overview

Minimal Settings screen (S28) plus `SettingsRepository` on `shared_preferences`, preloaded before `runApp`, so palette and language switch instantly and persist with no first-frame flash.

## Stories Included

- [ ] **008-settings-screen**: General (Language, Palette) + About (version, licenses) - Priority: Must
- [ ] **009-switch-palette**: Palette picker, persistence, preload - Priority: Must
- [ ] **010-switch-language**: Language picker, persistence, overrides device locale - Priority: Must

## Bolt Type

**Type**: Simple Construction Bolt
**Definition**: `.specsmd/aidlc/templates/construction/bolt-types/simple-construction-bolt.md`

## Stages

- [ ] **1. plan**: Pending → implementation-plan.md
- [ ] **2. implement**: Pending → source code + implementation-walkthrough.md
- [ ] **3. test**: Pending → tests + test-walkthrough.md

## Expected Outputs

- `lib/features/settings/{data,application,presentation}/*`
- `main.dart` preload + `ProviderScope` overrides
- Repository unit tests (mock prefs), widget tests for pickers and immediate re-theme/re-localize
- Manual check on a real phone: force-stop → relaunch keeps choices; cold start < 2 s

## Dependencies

### Requires
- 002-app-foundation-ui

### Enables
- None in this intent (002-local-library-and-player builds on it)

## Success Criteria

- [ ] All stories implemented
- [ ] All acceptance criteria met
- [ ] `flutter analyze` clean, `dart format` clean
- [ ] Tests passing locally and in CI

## Notes

Closes intent 001. Run the intent's "Done when" checks on emulator and a real phone at the end of the test stage.
