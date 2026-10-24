---
id: 002-app-foundation-ui
unit: 001-app-foundation-ui
intent: 001-app-foundation
type: simple-construction-bolt
status: complete
stories:
  - 005-localization-and-initial-locale
  - 006-app-shell-and-routing
  - 007-shared-empty-state-component
created: 2026-10-23T22:22:46Z
started: 2026-10-24T18:18:52Z
completed: 2026-10-24T18:38:37Z
current_stage: null
stages_completed:
  - name: plan
    completed: 2026-10-24T18:25:01Z
    artifact: implementation-plan.md
  - name: implement
    completed: 2026-10-24T18:33:43Z
    artifact: implementation-walkthrough.md
  - name: test
    completed: 2026-10-24T18:38:37Z
    artifact: test-walkthrough.md
requires_bolts:
  - 001-app-foundation-ui
enables_bolts:
  - 003-app-foundation-ui
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

- [x] **005-localization-and-initial-locale**: ARB en/am/om/ti, device-locale resolution, `om` Material fallback - Priority: Must
- [x] **006-app-shell-and-routing**: Stateful shell route, bottom nav, back behavior, `/settings` route - Priority: Must
- [x] **007-shared-empty-state-component**: C07 empty/error/offline + "Coming soon" on tabs - Priority: Must

## Bolt Type

**Type**: Simple Construction Bolt
**Definition**: `.specsmd/aidlc/templates/construction/bolt-types/simple-construction-bolt.md`

## Stages

- [x] **1. plan**: Complete → implementation-plan.md
- [x] **2. implement**: Complete → source code + implementation-walkthrough.md
- [x] **3. test**: Complete → tests + test-walkthrough.md

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

- [x] All stories implemented
- [x] All acceptance criteria met
- [x] `flutter analyze` clean, `dart format` clean
- [ ] Tests passing locally and in CI (local: yes; CI: pending a GitHub remote)

## Notes

Uncertainty is mainly the `om`/`ti` Material localization fallback. Verify early with the device set to Afaan Oromoo.
