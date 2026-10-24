---
id: 003-app-foundation-ui
unit: 001-app-foundation-ui
intent: 001-app-foundation
type: simple-construction-bolt
status: complete
stories:
  - 008-settings-screen
  - 009-switch-palette
  - 010-switch-language
  - 011-switch-theme-mode
created: 2026-10-23T22:22:46Z
started: 2026-10-24T18:40:28Z
completed: 2026-10-24T19:13:04Z
current_stage: null
stages_completed:
  - name: plan
    completed: 2026-10-24T18:42:08Z
    artifact: implementation-plan.md
  - name: implement
    completed: 2026-10-24T19:09:05Z
    artifact: implementation-walkthrough.md
  - name: test
    completed: 2026-10-24T19:13:04Z
    artifact: test-walkthrough.md
requires_bolts:
  - 002-app-foundation-ui
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

Minimal Settings screen (S28), light/dark theme modes (story 011, added during construction), plus `SettingsRepository` on `shared_preferences`, preloaded before `runApp`, so palette and language switch instantly and persist with no first-frame flash.

## Stories Included

- [x] **008-settings-screen**: General (Language, Palette) + About (version, licenses) - Priority: Must
- [x] **009-switch-palette**: Palette picker, persistence, preload - Priority: Must
- [x] **010-switch-language**: Language picker, persistence, overrides device locale - Priority: Must
- [x] **011-switch-theme-mode**: System / Light / Dark theme, light version of each palette (added 2026-10-24) - Priority: Must

## Bolt Type

**Type**: Simple Construction Bolt
**Definition**: `.specsmd/aidlc/templates/construction/bolt-types/simple-construction-bolt.md`

## Stages

- [x] **1. plan**: Complete → implementation-plan.md
- [x] **2. implement**: Complete (incl. story 011, scope change 2026-10-24) → source code + implementation-walkthrough.md
- [x] **3. test**: Complete → tests + test-walkthrough.md

## Expected Outputs

- `lib/features/settings/{data,application,presentation}/*`
- `main.dart` preload + `ProviderScope` overrides
- Repository unit tests (mock prefs), widget tests for pickers, the Appearance sheet and immediate re-theme/re-localize; light token and contrast tests
- Manual check on a real phone: force-stop → relaunch keeps choices; cold start < 2 s

## Dependencies

### Requires
- 002-app-foundation-ui

### Enables
- None in this intent (002-local-library-and-player builds on it)

## Success Criteria

- [x] All stories implemented
- [x] All acceptance criteria met
- [x] `flutter analyze` clean, `dart format` clean
- [ ] Tests passing locally and in CI (local: yes; CI: pending a GitHub remote)

## Notes

Closes intent 001. Run the intent's "Done when" checks on emulator and a real phone at the end of the test stage.
