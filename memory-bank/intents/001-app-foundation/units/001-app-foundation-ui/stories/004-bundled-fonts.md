---
id: 004-bundled-fonts
unit: 001-app-foundation-ui
intent: 001-app-foundation
status: draft
priority: must
created: 2026-10-23T22:22:46Z
assigned_bolt: 001-app-foundation-ui
implemented: false
---

# Story: 004-bundled-fonts

## User Story

**As a** listener who reads Ethiopic script
**I want** Ge'ez text to render correctly even with no internet and on phones without Ethiopic system fonts
**So that** I never see empty boxes instead of letters

## Acceptance Criteria

- [ ] **Given** a fresh install with network disabled, **When** the app shows "ዜማ" and "ስብሐት ለእግዚአብሔር", **Then** they render with Noto Sans Ethiopic (no tofu boxes)
- [ ] **Given** the theme, **When** Latin text renders, **Then** it uses Inter; Ethiopic characters fall back to Noto Sans Ethiopic
- [ ] **Given** Ethiopic text styles, **When** inspected, **Then** line height is ≥ 1.4
- [ ] **Given** the app, **When** it runs, **Then** no font is fetched over the network
- [ ] **Given** About → Licenses, **When** opened, **Then** the SIL OFL licenses for Inter and Noto Sans Ethiopic are listed

## Technical Notes

- Put TTFs in `apps/mobile/assets/fonts/` (Inter 400/500/600/700; Noto Sans Ethiopic 400/500/600/700, or variable fonts if supported).
- Declare families in `pubspec.yaml`; `fontFamily: 'Inter'`, `fontFamilyFallback: ['NotoSansEthiopic']`.
- Register OFL texts via `LicenseRegistry.addLicense` in `main()`.
- A widget/golden test with Ethiopic text guards against regressions.

## Dependencies

### Requires
- 003-theme-tokens-and-palettes (text theme lives in theme)

### Enables
- 008-settings-screen (license page entry), all Ethiopic UI later

## Edge Cases

| Scenario | Expected Behavior |
|----------|-------------------|
| Mixed Latin + Ethiopic in one line | Both scripts render; baseline aligned |
| System font scale 1.3× | Text scales; no clipping of tall glyphs |

## Out of Scope

- Serif fonts (decided: sans only)
