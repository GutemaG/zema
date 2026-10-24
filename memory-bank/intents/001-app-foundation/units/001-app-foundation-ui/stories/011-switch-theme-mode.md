---
id: 011-switch-theme-mode
unit: 001-app-foundation-ui
intent: 001-app-foundation
status: complete
priority: must
created: 2026-10-24T19:05:00Z
assigned_bolt: 003-app-foundation-ui
implemented: true
---

# Story: 011-switch-theme-mode

> Added during construction of bolt 003 (scope change requested by the product owner on
> 2026-10-24). It replaces the earlier "dark only" decision.

## User Story

**As a** listener
**I want** to choose a light or dark appearance, or follow my phone's setting
**So that** the app is comfortable to read in daylight as well as at night

## Acceptance Criteria

- [ ] **Given** Settings → General, **When** displayed, **Then** it shows one Appearance row whose value combines palette and mode (e.g. "Night Vigil · System")
- [ ] **Given** the Appearance row, **When** tapped, **Then** one sheet opens with a System / Light / Dark switch and a preview card per palette (Night Vigil, Wine) drawn in the current mode; each tap applies and saves immediately, the sheet stays open to try combinations, and Done closes it
- [ ] **Given** no saved theme, **When** the app starts, **Then** it follows the phone's dark-mode setting (System is the default)
- [ ] **Given** Theme → Light, **When** picked, **Then** every visible screen switches to the light version of the current palette immediately and the choice survives a relaunch (first frame already light)
- [ ] **Given** Theme → System, **When** the phone switches between light and dark, **Then** the app follows without a restart
- [ ] **Given** both palettes, **When** used in light mode, **Then** each has its own light colors (4 color sets in total), defined as `ZemaColors` instances and matching `docs/design-system.md`
- [ ] **Given** the light colors, **When** checked, **Then** `text`/`muted`/`accentText` on `bg`/`surface` are ≥ 4.5:1 and `onPrimary` on `primary` is ≥ 4.5:1
- [ ] **Given** an unknown saved theme value, **When** the app starts, **Then** System is used and nothing crashes
- [ ] **Given** unit tests, **When** run, **Then** `SettingsRepository` round-trips the theme mode

## Technical Notes

- `ThemeMode` stored under key `themeMode` (`system` / `light` / `dark`).
- `MaterialApp.router(theme: light, darkTheme: dark, themeMode: …)`; both built by `buildTheme(palette, brightness)`.
- `ZemaPalette` carries a dark and a light `ZemaColors`; the preview cards show the colors of the current brightness.
- Theme and Palette were first built as two rows; the product owner asked to merge them into one choice (2026-10-24), so they share one Appearance row and sheet.

## Dependencies

### Requires
- 003-theme-tokens-and-palettes, 008-settings-screen, 009-switch-palette

### Enables
- Light variants of all later screens (they read tokens, so no extra work)

## Edge Cases

| Scenario | Expected Behavior |
|----------|-------------------|
| Phone switches dark mode while the app is open on System | Re-themes immediately |
| Gold `primary` used for thin progress bars in light mode | Low contrast (≈ 1.9:1); later screens use `accent` for thin indicators in light mode |

## Out of Scope

- Native launch screen colors per mode (stays as is)
- A designer-reviewed light palette (the drafted tokens are used until a design pass)
