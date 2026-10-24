---
stage: plan
bolt: 002-app-foundation-ui
created: 2026-10-24T18:18:52Z
---

## Implementation Plan: app-foundation-ui (bolt 2 of 3)

### Objective

Replace the bolt 1 placeholder screen with the real app shell. That means
localization in four languages with automatic first-launch language, a go_router
four-tab shell under a Riverpod `ProviderScope`, and the shared C07
empty/error/offline component. C07 shows "Coming soon" on every tab and handles
unknown routes.

### Deliverables

**005 – Localization and first-launch language**
- `apps/mobile/l10n.yaml`: gen-l10n reads ARB files from `lib/l10n/` and writes the
  generated `AppLocalizations` to `lib/l10n/generated/` (already excluded from
  analysis). The template is `app_en.arb`, and getters are non-nullable.
- `lib/l10n/app_en.arb` holds every key with descriptions. The keys are `appTitle`,
  `navHome`, `navSearch`, `navLibrary`, `navContribute`, `homeSettingsTooltip`,
  `comingSoonTitle`, one `…ComingSoonMessage` per tab plus Settings,
  `settingsTitle`, `errorNotFoundTitle`, `errorNotFoundMessage` and
  `actionGoHome`.
- `lib/l10n/app_am.arb`, `app_om.arb` and `app_ti.arb` translate the nav labels,
  "Coming soon" and the app title. All other keys fall back to English (see
  "Translations to review" below).
- `lib/app/l10n/app_language.dart`: `enum AppLanguage { en, am, om, ti }`, where
  each value has a `Locale` and a native display name (English, አማርኛ, Afaan Oromoo,
  ትግርኛ). `resolveInitialLanguage({String? saved, List<Locale> deviceLocales})` is a
  pure function with these rules:
  - A valid saved code wins.
  - Otherwise, use the first device locale whose language code is supported.
    Region variants like `am_ET` count.
  - Otherwise, use English.
- `lib/app/l10n/fallback_localizations.dart`: Material, Cupertino and Widgets
  delegates for `om` and `ti` that load the English built-in strings. Flutter 3.47
  ships `am` and `en` but not `om` or `ti`, which I checked against the SDK.
- `lib/app/l10n/language_providers.dart` has two providers:
  - `savedLanguageCodeProvider` always returns `null` in this bolt. Bolt 3 overrides it
    from `shared_preferences`.
  - `appLanguageProvider` computes the active language from the saved code and the
    device's locales.

**006 – App shell, bottom navigation and routing**
- Dependencies are `flutter_riverpod` 3.x, `go_router` 18.x, and
  `flutter_localizations` with `intl` (both from the SDK).
- `lib/main.dart` wraps `ZemaApp` in a `ProviderScope`.
- `lib/app/zema_app.dart` becomes a `ConsumerWidget` using `MaterialApp.router`. It
  takes the locale from `appLanguageProvider`, the theme from a `paletteProvider`
  (always Night Vigil until bolt 3), and the localization delegates including the
  fallbacks. The window title comes from `appTitle`.
- `lib/app/router.dart` defines `routerProvider`, which builds the `GoRouter`:
  - Starts at `/home`.
  - Uses `StatefulShellRoute.indexedStack` with branches `/home`, `/search`,
    `/library` and `/contribute`.
  - Has a top-level `/settings` route that opens above the shell.
  - Shows C07 (`error`) with a "Go home" action for unknown routes.
- `lib/app/app_shell.dart` is the shell scaffold. It holds the branch stack and the
  bottom bar, and handles back presses:
  - Android back on a non-Home tab root goes to Home.
  - Back on Home exits the app.
  - Re-tapping the active tab pops it to its root.
- `lib/app/zema_nav_bar.dart` is a custom bottom bar that matches the canvas:
  - Each item is an icon plus a label, with no indicator pill.
  - The active item is `primaryText` and bold; the others are `muted`.
  - There is a thin `line` border on top.
  - Labels are one line and ellipsize, so the bar height stays fixed.
  - Each item is at least 44×44 and exposes a "selected" state and a localized label to
    TalkBack.
- The four tab screens each show the C07 "Coming soon" state:
  `lib/features/home/presentation/home_screen.dart`, `search/…/search_screen.dart`,
  `library/…/library_screen.dart` and `contribute/…/contribute_screen.dart`. Home also
  has a header with the app title and a gear `IconButton` (localized tooltip, at least
  44×44) that opens `/settings`.
- `lib/features/settings/presentation/settings_screen.dart` is a temporary screen: an
  app bar with back and "Settings", plus C07 "Coming soon". Bolt 3 replaces its body.

**007 – Shared empty / error / offline state (C07)**
- `lib/shared/widgets/empty_state.dart` contains:
  - An `EmptyStateKind` enum (`empty`, `error`, `offline`), each with its own outline
    icon.
  - An `EmptyState` widget that takes a kind, title, message, and an optional action
    label with callback.
  - The layout is centered and scrolls when there isn't enough height.
  - The icon and message use `muted`, the title uses `text`, and the button is
    `primary`, at least 44 px tall and not fixed-width.

### Dependencies

- **flutter_riverpod 3.4.x**: root `ProviderScope`, router, language and palette
  providers.
- **go_router 18.1.x**: the stateful shell route and the `/settings` route. It requires
  Flutter 3.44 or later, and we run 3.47.
- **flutter_localizations / intl 0.20.x**: gen-l10n and the built-in Material strings.
- **Bolt 1**: theme, `ZemaColors`, typography and spacing.

### Technical Approach

- The language is resolved once in a provider and passed as `MaterialApp.locale`,
  instead of using `localeListResolutionCallback`. Then bolt 3's language switch only
  has to override `savedLanguageCodeProvider`.
- The custom nav bar is used instead of Material 3 `NavigationBar` because the canvas
  has no indicator pill, and `NavigationBar` labels can't be forced to ellipsize.
- The bolt 1 placeholder screen and its hard-coded ዜማ and "Zema" strings are removed.
  After this bolt, every user-visible string goes through `AppLocalizations`.
- A test scans `lib/` (excluding `lib/l10n/generated/`) for string literals passed to
  `Text(`, `tooltip:`, `semanticLabel:`, `label:` and `title:`, and fails if it finds
  any.
- Icons are Material outlined icons for now: home, search, library music, edit, and
  gear for settings. The canvas line-icon set can come later.

### Translations to review

These are draft strings. Please check them, especially Afaan Oromoo and Tigrinya. Any
key left out falls back to English.

- **Amharic (am)**: Home ዋና ገጽ · Search ፍለጋ · Library ቤተ መዛግብት · Contribute
  አስተዋጽኦ · Coming soon በቅርቡ ይመጣል · App title ዜማ
- **Afaan Oromoo (om)**: Home Fuula Duraa · Search Barbaadi · Library Kuusaa ·
  Contribute Gumaachi · Coming soon Dhiyootti ni dhufa · App title Zema
- **Tigrinya (ti)**: Home መበገሲ · Search ድለ · Library ቤተ-መዛግብቲ · Contribute ኣበርክቶ ·
  Coming soon ብቐረባ ክመጽእ እዩ · App title ዜማ

### Acceptance Criteria

- [ ] gen-l10n produces `AppLocalizations` for en, am, om and ti; English has every key
      and the others fall back to English for missing keys
- [ ] `resolveInitialLanguage` returns: the saved language when valid; `am` for device
      `am` or `am_ET`; `en` for `fr`; `en` for `[en_US, am]`; an unknown saved code is
      ignored
- [ ] With the locale set to `om` or `ti`, Material dialogs and back tooltips render
      English strings without crashing
- [ ] No user-visible string literals in `lib/` (enforced by a test)
- [ ] The root is wrapped in a `ProviderScope`; `MaterialApp.router` uses `routerProvider`
- [ ] Tapping each of the four tabs shows its screen and highlights the tab
      (`primaryText`, bold; others `muted`)
- [ ] Tab state, including scroll position, is kept when switching tabs; re-tapping the
      active tab pops it to its root
- [ ] Back on a non-Home tab goes to Home; back on Home exits
- [ ] `/home`, `/search`, `/library`, `/contribute` and `/settings` open the right
      screen; the gear in the Home header opens Settings above the shell
- [ ] An unknown route shows C07 `error` with "Go home" and does not crash
- [ ] Nav items and the gear have localized labels and are at least 44×44
- [ ] C07 shows the right icon, title and message for each kind; the button shows only
      when an action is given and calls it on tap
- [ ] Each tab shows C07 `empty` with a localized "Coming soon" and a tab-specific
      message
- [ ] No overflow at 1.3× text scale or with strings 40% longer, on a 360 dp wide screen
      (C07, nav bar, Home header)
- [ ] `flutter analyze` and `dart format` clean; all tests pass
