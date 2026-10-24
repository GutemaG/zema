---
intent: 001-app-foundation
phase: inception
status: units-decomposed
updated: 2026-10-23T22:22:46Z
---

# App Foundation - Unit Decomposition

## Units Overview

Project type `frontend-app` → backend units disabled, one feature-based frontend unit
(`{intent}-ui`, simple-construction-bolt). This intent decomposes into **1 unit**:

### Unit 1: 001-app-foundation-ui

**Description**: The Flutter app shell in `apps/mobile`: tooling/CI, app identity, theme
tokens and palettes, bundled fonts, localization, bottom-nav shell with routing, the
shared C07 empty-state component, and the minimal Settings screen with persisted
language and palette.

**Stories**:

- 001-project-tooling-and-ci
- 002-app-identity
- 003-theme-tokens-and-palettes
- 004-bundled-fonts
- 005-localization-and-initial-locale
- 006-app-shell-and-routing
- 007-shared-empty-state-component
- 008-settings-screen
- 009-switch-palette
- 010-switch-language

**Deliverables**:

- `apps/mobile/lib/app/` (app widget, router, theme, l10n setup), `apps/mobile/lib/shared/` (C07), `apps/mobile/lib/features/{home,search,library,contribute,settings}/`
- ARB files for en, am, om, ti; bundled font assets
- Strict `analysis_options.yaml` in `apps/mobile` and `packages/zema_core`
- `.github/workflows/ci.yaml`
- Widget and unit tests

**Dependencies**:

- Depends on: none
- Depended by: every later intent (002+ build on the shell, theme, l10n and C07)

**Estimated Complexity**: M

## Requirement-to-Unit Mapping

- **FR-1** App shell with bottom navigation → `001-app-foundation-ui`
- **FR-2** Placeholder content using C07 → `001-app-foundation-ui`
- **FR-3** Theme from design tokens → `001-app-foundation-ui`
- **FR-4** Palette switch with persistence → `001-app-foundation-ui`
- **FR-5** Bundled fonts → `001-app-foundation-ui`
- **FR-6** Routing and state management → `001-app-foundation-ui`
- **FR-7** Localization scaffold and initial locale → `001-app-foundation-ui`
- **FR-8** Language switch with persistence → `001-app-foundation-ui`
- **FR-9** Settings screen (S28, minimal) → `001-app-foundation-ui`
- **FR-10** App identity → `001-app-foundation-ui`
- **FR-11** Tooling and CI → `001-app-foundation-ui`

## Unit Dependency Graph

```text
[001-app-foundation-ui]   (single unit, no cross-unit dependencies)
```

## Execution Order

1. Bolt 001: tooling, identity, theme, fonts (stories 001–004)
2. Bolt 002: localization, shell + routing, C07 (stories 005–007)
3. Bolt 003: Settings screen, palette + language persistence (stories 008–010)
