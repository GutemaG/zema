---
stage: implement
bolt: 003-app-foundation-ui
created: 2026-10-24T18:50:00Z
---

## Implementation Walkthrough: app-foundation-ui (bolt 3 of 3)

### Summary

Settings is now the minimal S28 screen: a General card (Language, Theme) and an About
card (Version, Open-source licenses), with bottom-sheet pickers for language and
palette. The choices are saved in `shared_preferences` and loaded in `main()` before the
first frame. A change applies at once and survives a relaunch with no flash of the
defaults.

### Structure Overview

The settings feature follows the three-layer layout from the coding standards.
- `data/` holds the `AppSettings` value and the repository over `shared_preferences`.
- `application/` holds the Riverpod providers: the repository and initial settings
  (both set in `main()`), the settings controller, and the app version.
- `presentation/` holds the screen and its widgets (section card, row, two pickers).

The app-level palette and saved-language providers from bolts 1 and 2 now read from the
settings controller, so the root widget and language resolution are unchanged.

### Completed Work

- [x] `apps/mobile/lib/features/settings/data/app_settings.dart` - immutable settings value: palette and optional language code, with equality and copyWith
- [x] `apps/mobile/lib/features/settings/data/settings_repository.dart` - reads settings synchronously from loaded preferences (unknown values fall back to defaults) and saves palette and language, throwing a typed exception when a write fails
- [x] `apps/mobile/lib/features/settings/application/settings_controller.dart` - repository and initial-settings providers, plus the settings controller: updates state first, then saves; a failed save is logged and the new value kept; re-picking the current value does nothing
- [x] `apps/mobile/lib/features/settings/application/app_version_provider.dart` - installed version as `version (build)`
- [x] `apps/mobile/lib/app/theme/palette_provider.dart` - active palette now comes from settings
- [x] `apps/mobile/lib/app/l10n/language_providers.dart` - saved language now comes from settings
- [x] `apps/mobile/lib/main.dart` - loads preferences and settings before `runApp`, injects them through `ProviderScope` overrides, debug-only log output
- [x] `apps/mobile/lib/features/settings/presentation/settings_screen.dart` - S28 minimal: General (Language, Theme) and About (Version, licenses); version shows "—" on failure; licenses open Flutter's license page with app name and version
- [x] `apps/mobile/lib/features/settings/presentation/widgets/settings_group.dart` - uppercase section label and rounded card with dividers
- [x] `apps/mobile/lib/features/settings/presentation/widgets/settings_row.dart` - label, right-aligned value and ›; one merged screen-reader node; at least 56 px tall
- [x] `apps/mobile/lib/features/settings/presentation/widgets/palette_picker.dart` - Theme bottom sheet with radio options and swatches; localized palette names
- [x] `apps/mobile/lib/features/settings/presentation/widgets/language_picker.dart` - Language bottom sheet with the four languages in their own scripts; picking the active one only closes
- [x] `apps/mobile/lib/app/theme/zema_theme.dart` - app bar and bottom sheet styling: no Material 3 scroll tint, left-aligned titles, `surface` sheets with drag handle
- [x] `apps/mobile/lib/l10n/app_*.arb` and `lib/l10n/generated/*` - 8 new English keys, unused Settings placeholder message removed, draft am/om/ti for "Settings" and "Language"
- [x] `apps/mobile/pubspec.yaml` - new dependencies

### Key Decisions

- **Preloaded settings, not async state**: `main()` awaits `SharedPreferences` once, and
  the controller starts with the saved values. No loading state, no wrong first frame.
- **Typed write failure**: `setString` returning false becomes
  `SettingsWriteException`, so the controller logs it the same way as a thrown error.
- **App-wide app bar style**: left-aligned titles (iOS centered them; the canvas aligns
  left next to the back chevron) and no gold scroll tint, which Material 3 adds by
  default.
- **Value rows right-aligned**: the value takes up to half the row and sits against the
  › or the row's end.

### Deviations from Plan

- The theme gained app bar and bottom sheet settings, which the plan didn't list. They
  came out of the simulator check: the title was centered on iOS and values sat mid-row.
- Bolt 2 tests are unchanged and still pass. They override the palette and
  saved-language providers directly, which still works.
- During Stage 3, settings loading moved out of `main()` into
  `features/settings/application/settings_bootstrap.dart` so tests use the same startup
  code. The version provider stopped retrying, and both pickers became `toggleable`
  (see the test report).

### Dependencies Added

- [x] `shared_preferences` ^2.5.6 - stores palette and language
- [x] `package_info_plus` ^10.2.2 - version and build number for the About card
- [x] `logging` ^1.3.0 - warning when a settings save fails

### Developer Notes

- **Simulator check (iOS 27, iPhone 17)**:
  - Settings opened directly with `flutter run --route /settings` shows both cards and
    the real `1.0.0 (1)`.
  - With `paletteId=wine` and `localeCode=am` written into the app's preferences file,
    a relaunch opened Settings already in Wine and Amharic.
  - A standalone cold start (without `flutter run`) showed the full Amharic Home in Wine
    within 2 seconds.
  - The test preferences were removed afterwards.
- `shared_preferences` on iOS stores keys with a `flutter.` prefix in the app
  container's `Library/Preferences/com.zemaapp.zema.plist`. That is useful for setting
  up device checks.
- Picking a value in the pickers can't be driven from the command line on the simulator.
  Stage 3 widget tests cover it.
- Not checked: Android force-stop/relaunch and cold start on a real phone (no device
  available).

---

## Addendum (2026-10-24T19:20:00Z): story 011 – theme mode

### Summary

The app now has a Theme setting (System, Light, Dark; default System) separate from
Palette. Each palette has a light version, so all four combinations work. With System the
app follows the phone's dark-mode setting live.

### Completed Work

- [x] `apps/mobile/lib/app/theme/zema_colors.dart` - light versions of Night Vigil and Wine (draft tokens from `docs/design-system.md`)
- [x] `apps/mobile/lib/app/theme/zema_palette.dart` - each palette carries dark and light colors and picks one by brightness
- [x] `apps/mobile/lib/app/theme/zema_theme.dart` - builds a light or dark theme for a palette (light or dark color scheme from the same tokens)
- [x] `apps/mobile/lib/app/theme/palette_provider.dart` - adds the theme-mode provider read from settings
- [x] `apps/mobile/lib/app/zema_app.dart` - light theme, dark theme and theme mode from settings
- [x] `apps/mobile/lib/features/settings/data/app_settings.dart` - adds the theme mode (System by default)
- [x] `apps/mobile/lib/features/settings/data/settings_repository.dart` - stores the theme mode under `themeMode`; unknown values fall back to System; shared enum-by-name parsing
- [x] `apps/mobile/lib/features/settings/application/settings_controller.dart` - `setThemeMode`, same apply-then-save behavior
- [x] `apps/mobile/lib/features/settings/presentation/widgets/theme_mode_picker.dart` - Theme bottom sheet (System / Light / Dark with icons)
- [x] `apps/mobile/lib/features/settings/presentation/widgets/palette_picker.dart` - titled "Palette"; swatches show the colors of the mode on screen
- [x] `apps/mobile/lib/features/settings/presentation/settings_screen.dart` - General now has Language, Theme and Palette
- [x] `apps/mobile/lib/l10n/app_en.arb` and generated files - Palette and the three mode names
- [x] Docs updated: `docs/design-system.md` (light token table and light-mode gold rule), `docs/roadmap.md`, `standards/ux-guide.md`, `standards/tech-stack.md`, intent requirements (FR-3, FR-9, new FR-12), unit brief, stories 008 and 011, story index

### Key Decisions

- **Light and dark color schemes from the same tokens**: the dark theme is unchanged.
  The light one uses the light tokens. No seed-generated colors.
- **"Theme" now means light/dark; the palette row is "Palette"**: this reverses the
  earlier choice of calling the palette row "Theme", because both settings now exist.

### Developer Notes

- Simulator check: with nothing saved and the simulator in light appearance, Settings
  opens light (parchment background, dark text). Switching the simulator to dark
  (`xcrun simctl ui <device> appearance dark`) re-themed the open app at once. The palette
  sheet in dark mode shows both swatches.
- 8 existing tests assumed a dark-only app or the old row label. They are updated in
  Stage 3.

### Revision (2026-10-24T19:40:00Z): one Appearance choice

At the product owner's request, Theme and Palette were merged into one choice.

- [x] `apps/mobile/lib/features/settings/presentation/widgets/appearance_picker.dart` - the Appearance sheet: a System / Light / Dark segmented switch, two palette preview cards (a miniature screen in each palette's colors for the current mode, with the selected card outlined in `accent` and checked), and a Done button. Each tap applies and saves at once, and the sheet stays open. It also holds the palette, mode and combined-name helpers.
- [x] `palette_picker.dart` and `theme_mode_picker.dart` - removed
- [x] `apps/mobile/lib/features/settings/presentation/settings_screen.dart` - General has Language and Appearance ("Night Vigil · System")
- [x] `apps/mobile/lib/l10n/app_en.arb` - added Appearance and Done; removed the separate Theme and Palette labels; Wine shortened to "Wine"
- [x] Docs: stories 008 and 011, intent FR-9 and FR-12, unit brief, UX guide, design system and plan revision describe the single Appearance row

Simulator: Settings shows one Appearance row. A Wine + Light choice made by hand on the
simulator was still applied after a relaunch, with the screen in the Wine light colors.
