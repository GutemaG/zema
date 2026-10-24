---
id: 003-theme-tokens-and-palettes
unit: 001-app-foundation-ui
intent: 001-app-foundation
status: draft
priority: must
created: 2026-10-23T22:22:46Z
assigned_bolt: 001-app-foundation-ui
implemented: false
---

# Story: 003-theme-tokens-and-palettes

## User Story

**As a** developer building any screen
**I want** every design token from `docs/design-system.md` available through the theme
**So that** screens match the approved Night Vigil design without hard-coded colors

## Acceptance Criteria

- [ ] **Given** `ZemaColors`, **When** I read it, **Then** it has all 15 tokens (bg, surface, line, text, muted, faint, primary, onPrimary, primaryText, accent, accentText, soft, tile, tileFg, shadow)
- [ ] **Given** the Night Vigil and Wine palettes, **When** a unit test compares every token to the hex values in `docs/design-system.md`, **Then** all 30 values match
- [ ] **Given** `buildTheme(palette)`, **When** called, **Then** it returns a dark `ThemeData` whose `ColorScheme` maps surface→bg, primary→primary, onPrimary→onPrimary and which includes `ZemaColors` as an extension
- [ ] **Given** `ZemaColors.lerp`, **When** the palette changes, **Then** colors interpolate without error
- [ ] **Given** the codebase, **When** a test scans `lib/` outside `lib/app/theme/`, **Then** no `Color(0x` literals are found
- [ ] **Given** no saved palette, **When** the app starts, **Then** Night Vigil is used

## Technical Notes

- Location: `lib/app/theme/` (`zema_colors.dart`, `zema_palette.dart`, `zema_theme.dart`, `zema_spacing.dart`).
- Access via `context.zemaColors` extension getter.
- Spacing/radius constants: radius 12 / 16 / 24 / pill; side padding 16–20; list row 66; min tap 44.
- Text theme sizes per design-system typography table; Ethiopic styles `height ≥ 1.4`.

## Dependencies

### Requires
- None

### Enables
- 004-bundled-fonts (text theme), 006, 007, 008, 009

## Edge Cases

| Scenario | Expected Behavior |
|----------|-------------------|
| Widget reads `ZemaColors` outside a themed tree (tests) | Clear assertion message telling to wrap in the app theme |

## Out of Scope

- Light palette; album-art dynamic colors (002/003)
