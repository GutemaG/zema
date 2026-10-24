---
id: 009-switch-palette
unit: 001-app-foundation-ui
intent: 001-app-foundation
status: complete
priority: must
created: 2026-10-23T22:22:46Z
assigned_bolt: 003-app-foundation-ui
implemented: true
---

# Story: 009-switch-palette

## User Story

**As a** listener
**I want** to choose between Night Vigil and Night Vigil · Wine, and have the app remember it
**So that** the app looks the way I prefer every time I open it

## Acceptance Criteria

- [ ] **Given** Settings → Palette, **When** I pick Wine, **Then** every visible screen re-themes immediately without a restart
- [ ] **Given** I picked Wine, **When** I force-stop and relaunch, **Then** the first frame already uses Wine (no flash of Night Vigil)
- [ ] **Given** no saved palette or an unknown saved value, **When** the app starts, **Then** Night Vigil is used and nothing crashes
- [ ] **Given** the picker, **When** open, **Then** the current palette is selected and each option shows a small swatch (bg + primary)
- [ ] **Given** unit tests, **When** run, **Then** `SettingsRepository` round-trips the palette using `SharedPreferences.setMockInitialValues`

## Technical Notes

- `SettingsRepository` (`features/settings/data/`) over `shared_preferences`; key `paletteId`.
- Load `AppSettings` in `main()` before `runApp`; inject through `ProviderScope(overrides: …)`; a `Notifier` updates state then persists.
- `MaterialApp.router` reads `theme` from the settings provider.

## Dependencies

### Requires
- 003-theme-tokens-and-palettes, 008-settings-screen

### Enables
- 010-switch-language (reuses `SettingsRepository`)

## Edge Cases

| Scenario | Expected Behavior |
|----------|-------------------|
| Write to prefs fails | UI keeps new palette for the session; warning logged |

## Out of Scope

- Light theme, dynamic album-art colors
