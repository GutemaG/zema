---
stage: test
bolt: 003-app-foundation-ui
created: 2026-10-24T19:00:00Z
updated: 2026-10-24T19:25:00Z
---

## Test Report: app-foundation-ui (bolt 3 of 3)

Covers stories 008–010 and story 011 (theme mode and one Appearance choice), which was
added to this bolt as a scope change on 2026-10-24.

### Summary

- **Tests**: 141/141 passed (140 in `apps/mobile`, 1 in `packages/zema_core`)
- **Coverage**: 97.5% of lines in `apps/mobile/lib/`, excluding generated localizations
  (597/612). The uncovered lines are the `setString`-returns-false branch, `hashCode`
  and `toString`, and the real `PackageInfo` call.
- **CI sequence run locally**: format check, `flutter analyze`, `flutter test` and
  `dart test` all exit 0. The generated localizations are in sync.

### Test Files

- [x] `apps/mobile/test/helpers/pump_app.dart` - starts the app through the real settings bootstrap over mocked saved preferences; fakes device locales, the phone's light/dark setting (dark by default), start route and app version; can pump only the first frame
- [x] `apps/mobile/test/app/theme/zema_colors_test.dart` - dark and light token values for both palettes (60 values) against `docs/design-system.md`; contrast rules for all four color sets (`text`/`muted`/`primaryText` on `bg`/`surface` ≥ 4.5, `onPrimary` on `primary` ≥ 4.5, `accentText` on `soft` ≥ 4.5, `faint` on `bg` ≥ 3); palette dark/light mapping
- [x] `apps/mobile/test/app/theme/zema_theme_test.dart` - every palette in both brightnesses: brightness, ColorScheme mapping, extension, fonts, line height
- [x] `apps/mobile/test/app/zema_app_test.dart` - follows a light phone by default (Night Vigil light)
- [x] `apps/mobile/test/features/settings/data/settings_repository_test.dart` - defaults, including System; palette, theme mode and language round-trip with `setMockInitialValues`; key names; values from a previous run; unknown palette or theme mode falls back
- [x] `apps/mobile/test/features/settings/application/settings_controller_test.dart` - preloaded start; setPalette, setThemeMode and setLanguage update providers and save; re-picking saves nothing; failed saves keep values and log warnings; missing override fails clearly
- [x] `apps/mobile/test/features/settings/presentation/settings_screen_test.dart` - Settings cards and rows (Language, Appearance, Version, licenses); no other sections; values ("Night Vigil · System"); "—" version; license page; semantics and sizes; 1.3× in four languages; **Appearance sheet**: mode switch, two cards and Done; Wine applies at once, is saved and keeps the sheet open; Light switches a dark phone to light and the preview cards follow; Dark keeps a light phone dark; System follows the phone live in both directions; cards are selectable buttons for screen readers; sheet fits at 1.3× in four languages; Language picker (native names, immediate switch, saved, re-pick closes, Ethiopic line height); first frame uses saved palette, theme mode and language; unknown saved values fall back

### Acceptance Criteria Validation

Stories 008–010:
- ✅ **General and About cards with grouped rows and ›**: now Language and Appearance in General
- ✅ **Current values (language in its own script, palette and mode localized)**
- ✅ **Version as `version (build)`, "—" on failure**
- ✅ **License page lists packages and both font licenses**
- ✅ **No other S28 sections**
- ✅ **Rows labeled, ≥ 44 px, no overflow at 1.3×**
- ✅ **Palette applies immediately and is used on the first frame after relaunch; unknown → Night Vigil**
- ✅ **Language picker; immediate switch; saved language beats the device; re-pick closes**
- ✅ **Repository round-trip; failed save kept and logged**

Story 011:
- ✅ **One Appearance row ("Night Vigil · System") opening one sheet with mode switch and palette preview cards; taps apply and save at once; Done closes**: `settings_screen_test.dart`; row also seen on the iOS simulator
- ✅ **Nothing saved → follows the phone**: `zema_app_test.dart`, `settings_screen_test.dart`; seen on the simulator
- ✅ **Light/Dark apply immediately and survive relaunch (first frame)**: `settings_screen_test.dart`; Wine · Light survived a relaunch on the simulator
- ✅ **System follows the phone live**: `settings_screen_test.dart`; seen on the simulator (`simctl ui appearance dark`)
- ✅ **Four color sets matching the design system**: `zema_colors_test.dart`
- ✅ **Contrast rules for the light colors**: `zema_colors_test.dart`
- ✅ **Unknown saved theme → System**: `settings_repository_test.dart`, `settings_screen_test.dart`
- ✅ **Repository round-trips the theme mode**: `settings_repository_test.dart`

### Intent 001 "Done when" checks

- ✅ Four tabs switch and keep state (bolt 2 tests; simulator)
- ✅ Palette, theme mode and language apply immediately and survive a relaunch (tests;
  simulator)
- ✅ Ethiopic renders with the bundled font, offline (bolt 1 tests; simulator)
- ✅ Settings shows Language, Appearance, version and licenses, and nothing else
- ✅ Zero network calls (fonts bundled; no networking dependency)
- ⏳ **Launches on an Android emulator and a real phone**: the debug APK builds, but it
  hasn't been run on Android. No device is available here.
- ⏳ **Cold start < 2 s (release, mid-range phone)**: not measured. A debug build on the
  iOS simulator drew its first screen within 2 s.
- ⏳ **CI green**: every CI command passes locally; the workflow runs once the repo has a
  GitHub remote.

### Issues Found

- Picking the active option left the sheet open (fixed before story 011; the language
  picker is now `toggleable`).
- The version row stayed blank on failure because of Riverpod 3's automatic retry (fixed;
  retry is off for that provider).
- During story 011, eight existing tests assumed a dark-only app or the two-row layout.
  They were updated. The test helper now sets the phone's brightness explicitly.

### Notes

- **The tests can fail when they should**:
  - Without the preload override, the first-frame test fails.
  - Without the `om`/`ti` fallback delegates, the built-in-string tests fail (bolt 2).
  - With the theme mode forced to Dark, six tests fail: the light-phone default, Light,
    Dark, live System following, and both launch tests.
- The light tokens are a draft; when a design pass changes them, update
  `docs/design-system.md` and the expected values in `zema_colors_test.dart` together.
