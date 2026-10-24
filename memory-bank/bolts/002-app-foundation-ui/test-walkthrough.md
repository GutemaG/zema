---
stage: test
bolt: 002-app-foundation-ui
created: 2026-10-24T18:50:00Z
---

## Test Report: app-foundation-ui (bolt 2 of 3)

### Summary

- **Tests**: 87/87 passed (86 in `apps/mobile`, 1 in `packages/zema_core`)
- **Coverage**: 98.1% of lines in `apps/mobile/lib/`, excluding generated localizations
  (310/316)
- **CI sequence run locally**: format check, `flutter analyze`, `flutter test` and
  `dart test` all exit 0. The committed generated localizations match a fresh
  `flutter gen-l10n`.

### Test Files

- [x] `apps/mobile/test/helpers/pump_app.dart` - helpers: pump the full app with a fake device locale, saved language and start route; pump a widget in the app theme; set screen size and text scale
- [x] `apps/mobile/test/app/l10n/app_language_test.dart` - first-launch resolution: saved code wins, unknown saved code ignored, am / am_ET / om / ti_ER, fr → English, order of device locales, empty list; language codes and native names
- [x] `apps/mobile/test/app/l10n/localizations_test.dart` - four supported locales; am/om/ti fall back to English for missing keys; device am → Amharic UI; fr → English; saved language beats device; `om` and `ti` get English Material back tooltip and an about dialog without crashing
- [x] `apps/mobile/test/app/no_string_literals_test.dart` - fails on string literals passed to `Text(`, `tooltip:`, `semanticLabel:`, `label:`, `title:` or `message:` anywhere in `lib/` outside generated code
- [x] `apps/mobile/test/app/app_shell_test.dart` - tab switching and highlight colors and weights; Coming soon per tab; scroll position kept across tab switches; re-tap pops to root; back on another tab goes Home; back on Home exits; every route plus `/` redirect; gear opens Settings above the shell and back returns; unknown route shows the C07 error and Go home works; semantics labels, selected state, tap action and 44×44 targets (iOS tap-target and labeled-tap-target guidelines); localized semantics labels; no overflow at 1.3× on 360 dp in all four languages; long nav labels ellipsize with a fixed bar height
- [x] `apps/mobile/test/shared/widgets/empty_state_test.dart` - each kind's icon, title and message in English and Ethiopic, with and without an action; button only when both label and callback are given; design-token colors and 44 px button; no overflow at 1.3× with 40% longer strings on 360 dp; scrolls on a very short screen; tab title ellipsizes
- [x] `apps/mobile/test/app/zema_app_test.dart` - updated in Stage 2: app starts inside a ProviderScope, default and overridden palette

### Acceptance Criteria Validation

- ✅ **gen-l10n for en/am/om/ti; English fallback for missing keys**: `localizations_test.dart`; 10 keys per language still untranslated by design
- ✅ **resolveInitialLanguage rules (saved, am, am_ET, fr, [en_US, am], unknown saved)**: `app_language_test.dart`
- ✅ **om/ti Material widgets render English strings without crashing**: `localizations_test.dart`
- ✅ **No user-visible string literals in lib/**: `no_string_literals_test.dart`
- ✅ **ProviderScope root; MaterialApp.router uses routerProvider**: `zema_app_test.dart`, all app-level tests
- ✅ **Tabs open their screens; active tab primaryText + bold, others muted**: `app_shell_test.dart`
- ✅ **Tab state and scroll position kept; re-tap pops to root**: `app_shell_test.dart`
- ✅ **Back on another tab → Home; back on Home exits**: `app_shell_test.dart`
- ✅ **All five routes open the right screen; gear opens Settings above the shell**: `app_shell_test.dart`
- ✅ **Unknown route → C07 error with Go home, no crash**: `app_shell_test.dart`
- ✅ **Localized labels and ≥ 44×44 targets for nav items and the gear**: `app_shell_test.dart`
- ✅ **C07 icon/title/message per kind; button only with an action; callback fires**: `empty_state_test.dart`
- ✅ **Each tab shows C07 empty with localized Coming soon and its own message**: `app_shell_test.dart`, `localizations_test.dart`
- ✅ **No overflow at 1.3× or +40% strings on 360 dp (C07, nav bar, Home header)**: `empty_state_test.dart`, `app_shell_test.dart`
- ✅ **flutter analyze and dart format clean; all tests pass**

### Issues Found

- **Nav items had no tap action for screen readers** (fixed): the item's `Semantics`
  excluded its children's semantics, including the `InkWell` tap action. TalkBack would
  announce "Home, selected" but could not activate the tab. The `Semantics` node now has
  its own tap handler.
- Two test mistakes were corrected during the stage. The `om`/`ti` back-tooltip tests
  first opened Settings as the initial route, where there is no back button. The gear
  check first looked for a semantics label, while `IconButton` exposes its tooltip as
  the semantics tooltip.

### Notes

- **The fallback test can fail**: with the fallback delegates temporarily removed, all
  four `om`/`ti` built-in-string tests and the saved-Tigrinya test fail. They pass with
  the delegates restored.
- The re-tap test uses a small test-only shell with one sub-page per tab, because the
  production tabs have no sub-pages yet. It exercises the real `AppShell`.
- Widget tests use Flutter's test font, which draws each glyph one em wide. That makes
  the overflow tests stricter than real Inter or Noto text.
- Not checked on a device: tab interaction and the am/om/ti UI. The iOS simulator was
  checked in English only, since it can't be tapped or switched to another language from
  the command line.
