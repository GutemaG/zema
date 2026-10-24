---
id: 002-app-foundation-ui
unit: 001-app-foundation-ui
intent: 001-app-foundation
type: simple-construction-bolt
status: planned
stories:
  - 005-localization-and-initial-locale
  - 006-app-shell-and-routing
  - 007-shared-empty-state-component
created: 2026-10-23T22:22:46Z
started: null
completed: null
current_stage: null
stages_completed: []

requires_bolts: [001-app-foundation-ui]
enables_bolts: [003-app-foundation-ui]
requires_units: []
blocks: false

complexity:
  avg_complexity: 2
  avg_uncertainty: 2
  max_dependencies: 2
  testing_scope: 2
---

# Bolt: 002-app-foundation-ui

## Overview

Localization with first-launch language resolution, the go_router four-tab shell with Riverpod at the root, and the shared C07 empty-state component shown on every tab.

## Stories Included

- [ ] **005-localization-and-initial-locale**: ARB en/am/om/ti, device-locale resolution, `om` Material fallback - Priority: Must
- [ ] **006-app-shell-and-routing**: Stateful shell route, bottom nav, back behavior, `/settings` route - Priority: Must
- [ ] **007-shared-empty-state-component**: C07 empty/error/offline + "Coming soon" on tabs - Priority: Must

## Bolt Type

**Type**: Simple Construction Bolt
**Definition**: `.specsmd/aidlc/templates/construction/bolt-types/simple-construction-bolt.md`

## Stages

- [ ] **1. plan**: Pending → implementation-plan.md
- [ ] **2. implement**: Pending → source code + implementation-walkthrough.md
- [ ] **3. test**: Pending → tests + test-walkthrough.md

## Expected Outputs

- `l10n.yaml`, `lib/l10n/app_*.arb`, locale resolution + fallback delegates
- `lib/app/router.dart`, `lib/features/{home,search,library,contribute}/presentation/*`
- `lib/shared/widgets/empty_state.dart`
- Unit tests (locale resolution), widget tests (nav, back, unknown route, C07 variants, overflow at 1.3×)

## Dependencies

### Requires
- 001-app-foundation-ui

### Enables
- 003-app-foundation-ui

## Success Criteria

- [ ] All stories implemented
- [ ] All acceptance criteria met
- [ ] `flutter analyze` clean, `dart format` clean
- [ ] Tests passing locally and in CI

## Notes

Uncertainty is mainly the `om`/`ti` Material localization fallback. Verify early with the device set to Afaan Oromoo.
