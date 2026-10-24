---
stage: test
bolt: 001-app-foundation-ui
created: 2026-10-24T18:25:00Z
---

## Test Report: app-foundation-ui (bolt 1 of 3)

### Summary

- **Tests**: 31/31 passed (30 in `apps/mobile`, 1 in `packages/zema_core`)
- **Coverage**: 98.1% of lines in `apps/mobile/lib/app/` (102/104). `main.dart` is not
  covered because tests pump `ZemaApp` directly.
- **CI sequence run locally**: `flutter pub get`, `dart format --set-exit-if-changed`,
  `flutter analyze`, `flutter test` and `dart test` all pass. The workflow has not run on
  GitHub yet because the repo has no remote.

### Test Files

- [x] `apps/mobile/test/app/zema_app_test.dart` - smoke test: the app starts and shows ዜማ and "Zema"; Night Vigil is the default; a given palette is used
- [x] `apps/mobile/test/app/theme/zema_colors_test.dart` - all 15 tokens present; all 30 palette values match `docs/design-system.md`; lerp at 0, 0.5 and 1 and with null; copyWith; palette enum and fallback; helpful assertion when no theme is present
- [x] `apps/mobile/test/app/theme/zema_theme_test.dart` - for both palettes: dark brightness, ColorScheme mapping, extension present, Inter with Ethiopic fallback on every style, line height ≥ 1.4 on every style
- [x] `apps/mobile/test/app/theme/no_color_literals_test.dart` - fails on any `Color(0x` in `lib/` outside `lib/app/theme/`
- [x] `apps/mobile/test/app/theme/zema_typography_test.dart` - loads the bundled fonts through the asset bundle; Latin renders with Inter, Ethiopic with Noto Sans Ethiopic, Ethiopic in an Inter style falls back correctly, mixed scripts render, laid-out Ethiopic line height ≥ 1.4
- [x] `apps/mobile/test/app/licenses_test.dart` - OFL licenses for Inter and Noto Sans Ethiopic are registered
- [x] `packages/zema_core/test/zema_core_test.dart` - placeholder so `dart test` has a test to run

### Acceptance Criteria Validation

- ✅ **Strict analysis, zero issues**: `flutter analyze` and `dart analyze` are clean with strict modes and the six extra rules
- ✅ **Format check passes**: `dart format --output=none --set-exit-if-changed .` is clean
- ✅ **CI workflow**: pub get, format, analyze and both test suites with Flutter 3.47.x and read-only permissions. Commands verified locally; GitHub run pending a remote.
- ✅ **Counter test replaced; core has a test**: smoke test in `zema_app_test.dart`; `zema_core` has 1 passing test
- ✅ **App identity**: Android label "Zema", IDs `com.zemaapp.zema`, iOS display name "Zema". Seen on the iOS simulator home screen.
- ✅ **Placeholder icon**: gold ዜ on `#110D0B`, adaptive and monochrome layers generated. Seen on the iOS simulator.
- ✅ **15 tokens, 30 values verified**: `zema_colors_test.dart`
- ✅ **Dark theme, ColorScheme mapping, extension, lerp**: `zema_theme_test.dart`, `zema_colors_test.dart`
- ✅ **No color literals outside the theme folder**: `no_color_literals_test.dart`
- ✅ **Night Vigil is the default**: `zema_app_test.dart`, `zema_colors_test.dart`
- ✅ **Bundled fonts, Ethiopic fallback, line height ≥ 1.4**: `zema_typography_test.dart`, `zema_theme_test.dart`; Ethiopic seen rendering on the iOS simulator
- ✅ **OFL licenses registered**: `licenses_test.dart`
- ✅ **App launches to the themed placeholder**: iOS simulator (iPhone 17, iOS 27)

### Issues Found

- **Three text styles had no line height** (fixed): the text theme set 12 of Material's
  15 styles. `displayLarge`, `displayMedium` and `headlineLarge` fell back to Material
  defaults without a line height, so Ethiopic in them could render cramped. All 15 slots
  are now set in `zema_typography.dart`.

### Notes

- The font tests rely on the test font drawing every missing glyph as a one-em square.
  A throwaway check confirmed that text in a font that is not loaded measures exactly
  `length × fontSize`, so the tests do fail if the bundled fonts stop loading.
- Golden tests were left out on purpose: font rasterization differs between macOS and
  the Linux CI runner.
- An Android debug APK build was still running when this report was written (first
  Gradle run on a slow connection). Android was not launched because no emulator is
  configured.
- Per review feedback, the second Ethiopic line (ስብሐት ለእግዚአብሔር) was removed from the
  placeholder screen. ዜማ and "Zema" remain.
