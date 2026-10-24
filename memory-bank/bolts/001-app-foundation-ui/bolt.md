---
id: 001-app-foundation-ui
unit: 001-app-foundation-ui
intent: 001-app-foundation
type: simple-construction-bolt
status: planned
stories:
  - 001-project-tooling-and-ci
  - 002-app-identity
  - 003-theme-tokens-and-palettes
  - 004-bundled-fonts
created: 2026-10-23T22:22:46Z
started: null
completed: null
current_stage: null
stages_completed: []

requires_bolts: []
enables_bolts: [002-app-foundation-ui]
requires_units: []
blocks: false

complexity:
  avg_complexity: 1
  avg_uncertainty: 1
  max_dependencies: 2
  testing_scope: 1
---

# Bolt: 001-app-foundation-ui

## Overview

Groundwork with no navigation yet: strict analysis + CI, app label and placeholder icon, the `ZemaColors` theme with both palettes, and bundled fonts. At the end, the app launches to a themed placeholder screen showing Latin and Ethiopic sample text.

## Stories Included

- [ ] **001-project-tooling-and-ci**: Strict lints, format check, GitHub Actions CI - Priority: Must
- [ ] **002-app-identity**: Label "Zema", app ID check, placeholder icon - Priority: Must
- [ ] **003-theme-tokens-and-palettes**: `ZemaColors` (15 tokens × 2 palettes), `ThemeData` - Priority: Must
- [ ] **004-bundled-fonts**: Inter + Noto Sans Ethiopic bundled, fallback, licenses - Priority: Must

## Bolt Type

**Type**: Simple Construction Bolt
**Definition**: `.specsmd/aidlc/templates/construction/bolt-types/simple-construction-bolt.md`

## Stages

- [ ] **1. plan**: Pending → implementation-plan.md
- [ ] **2. implement**: Pending → source code + implementation-walkthrough.md
- [ ] **3. test**: Pending → tests + test-walkthrough.md

## Expected Outputs

- `analysis_options.yaml` (mobile, zema_core), `.github/workflows/ci.yaml`
- `apps/mobile/lib/app/theme/*`, `apps/mobile/assets/fonts/*`, `apps/mobile/assets/icon/*`
- Token-value unit test, no-color-literal test, Ethiopic render widget test, app smoke test

## Dependencies

### Requires
- None (first bolt)

### Enables
- 002-app-foundation-ui

## Success Criteria

- [ ] All stories implemented
- [ ] All acceptance criteria met
- [ ] `flutter analyze` clean, `dart format` clean
- [ ] Tests passing locally and in CI

## Notes

Replaces the default counter template. Font files must be downloaded once and committed (OFL). Pin Flutter 3.47 in CI.
