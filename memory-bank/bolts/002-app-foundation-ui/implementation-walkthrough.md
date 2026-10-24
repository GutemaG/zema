---
stage: implement
bolt: 002-app-foundation-ui
created: 2026-10-24T18:40:00Z
---

## Implementation Walkthrough: app-foundation-ui (bolt 2 of 3)

### Summary

The bolt 1 placeholder screen is replaced by the real app shell. The app has four
bottom-navigation tabs and a Settings route, runs under a Riverpod `ProviderScope`, and
picks its UI language automatically from the phone's settings. Every tab, the Settings
placeholder and unknown routes use the new shared C07 empty/error/offline component.

### Structure Overview

`lib/app/` holds app-wide wiring: the root widget, the router and route names, the shell
with its custom bottom bar, the not-found screen, and `l10n/` (language model,
resolution, providers, built-in string fallbacks). `lib/l10n/` holds the ARB files, and
gen-l10n writes `AppLocalizations` to `lib/l10n/generated/`. Each tab and Settings has a
screen under `lib/features/<feature>/presentation/`. Widgets shared by several features
(C07 and the tab page layout) live in `lib/shared/widgets/`.

### Completed Work

- [x] `apps/mobile/l10n.yaml` - gen-l10n settings: ARB folder, generated output folder, non-nullable getter, formatted output, untranslated-keys report in `build/`
- [x] `apps/mobile/lib/l10n/app_en.arb` - all 16 keys, each with a description for translators
- [x] `apps/mobile/lib/l10n/app_am.arb`, `app_om.arb`, `app_ti.arb` - draft translations of the app title, nav labels and "Coming soon"; other keys fall back to English
- [x] `apps/mobile/lib/l10n/generated/*` - generated `AppLocalizations` for en, am, om, ti (committed, so analysis and IDEs work without a generation step)
- [x] `apps/mobile/lib/app/l10n/app_language.dart` - supported languages with native names and locales, and the first-launch language resolution function
- [x] `apps/mobile/lib/app/l10n/fallback_localizations.dart` - Material, Cupertino and Widgets delegates that give `om` and `ti` the English built-in strings
- [x] `apps/mobile/lib/app/l10n/language_providers.dart` - saved language (always none until bolt 3), device locales, and the resulting active language
- [x] `apps/mobile/lib/app/theme/palette_provider.dart` - active palette (always Night Vigil until bolt 3)
- [x] `apps/mobile/lib/app/routes.dart` - route path constants
- [x] `apps/mobile/lib/app/router.dart` - router provider and route tree: `/` redirects to Home, the four-branch stateful shell, Settings above the shell, C07 error for unknown routes
- [x] `apps/mobile/lib/app/app_shell.dart` - shell scaffold: tab content, bottom bar, back-to-Home behavior, re-tap pops to root
- [x] `apps/mobile/lib/app/zema_nav_bar.dart` - custom bottom bar matching the canvas, with ellipsized labels, capped text scaling, a fixed height, at least 44×44 targets and selected-state semantics
- [x] `apps/mobile/lib/app/not_found_screen.dart` - C07 error with a "Go home" action
- [x] `apps/mobile/lib/app/zema_app.dart` - now a Riverpod consumer using `MaterialApp.router`, with locale from the language provider, theme from the palette provider, and app plus fallback localization delegates; the placeholder screen is removed
- [x] `apps/mobile/lib/main.dart` - wraps the app in a `ProviderScope`
- [x] `apps/mobile/lib/shared/widgets/empty_state.dart` - C07: three kinds with icons, title, message, optional action; centered and scrollable
- [x] `apps/mobile/lib/shared/widgets/tab_page.dart` - large-title header with optional actions, used by every tab
- [x] `apps/mobile/lib/features/home/presentation/home_screen.dart` - app title header with the Settings gear, C07 "Coming soon"
- [x] `apps/mobile/lib/features/{search,library,contribute}/presentation/*_screen.dart` - tab title header and C07 "Coming soon" with a tab-specific message
- [x] `apps/mobile/lib/features/settings/presentation/settings_screen.dart` - app bar with back and title, and C07 "Coming soon" until bolt 3
- [x] `apps/mobile/pubspec.yaml` - new dependencies; `generate: true` for gen-l10n
- [x] `apps/mobile/test/app/zema_app_test.dart` - updated for the provider-based app so the suite keeps compiling (the full new test set comes in Stage 3)

### Key Decisions

- **Language resolved in a provider and passed as `locale`**: bolt 3's language switch
  only needs to override the saved-language provider. No locale-resolution callback has
  to be re-run.
- **Device locales come from a provider**: tests can simulate a phone set to Amharic,
  French and so on without touching the platform.
- **Three fallback delegates, not two**: Flutter 3.47 also lacks built-in Widgets
  strings for `om` and `ti`, so Widgets needs a fallback alongside Material and
  Cupertino.
- **Generated localizations are committed and formatted**: `format: true` makes the
  output pass the CI format check. Analysis and IDEs work right after checkout.
- **Custom bottom bar**: matches the canvas (no indicator pill) and allows ellipsized
  labels. Text scaling inside the bar is capped at 1.3× to keep its height fixed.
- **Shared tab layout (`TabPage`)**: all four tabs share the large-title header from the
  canvas instead of repeating it.

### Deviations from Plan

- Added `lib/app/routes.dart`, `lib/shared/widgets/tab_page.dart` and a
  `deviceLocalesProvider`, none of which the plan listed. Each is small and keeps the
  other files simpler or testable.
- Updated bolt 1's `zema_app_test.dart` during this stage instead of Stage 3, because
  removing the `palette` constructor parameter broke compilation.

### Dependencies Added

- [x] `flutter_riverpod` ^3.4.3 - root scope and providers
- [x] `go_router` ^18.1.1 - stateful shell routing
- [x] `flutter_localizations` (SDK) - built-in Material, Cupertino and Widgets strings
- [x] `intl` ^0.20.2 - required by generated localizations; version pinned by flutter_localizations

### Developer Notes

- After editing ARB files, run `flutter gen-l10n` in `apps/mobile` (also runs on
  `flutter run`/`test`) and commit the generated files.
- `build/untranslated-messages.json` lists the keys each language still lacks.
- The draft am/om/ti strings need native-speaker review before release.
- The Android debug APK from bolt 1's code built successfully, in 24 minutes on the first
  Gradle run.
- Checked on the iOS simulator (English): the Home tab shows the large title, the
  Settings gear, the C07 "Coming soon" state, and the bottom bar with Home active. Tab
  switching, back behavior and the other languages are covered by Stage 3 widget tests,
  since the simulator can't be tapped from the command line.
