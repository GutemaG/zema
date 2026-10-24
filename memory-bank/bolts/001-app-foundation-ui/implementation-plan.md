---
stage: plan
bolt: 001-app-foundation-ui
created: 2026-10-24T17:58:46Z
---

## Implementation Plan: app-foundation-ui (bolt 1 of 3)

### Objective

Replace the default counter template with the groundwork every later bolt builds on:
strict analysis and CI, the "Zema" app identity, the `ZemaColors` theme with both
palettes, and bundled Latin and Ethiopic fonts. When it is done, the app launches to a
themed placeholder screen that shows Latin and Ethiopic sample text.

### Deliverables

**001 – Project tooling and CI**
- `apps/mobile/analysis_options.yaml`: `flutter_lints` plus the strict language modes and
  the extra rules from `standards/coding-standards.md`. Excludes `build/`, `android/`,
  `ios/`, `**/*.g.dart` and `lib/l10n/` output.
- `packages/zema_core/analysis_options.yaml`: `lints/recommended` plus the same strict
  modes and rules (Flutter-only rules left out).
- `.github/workflows/ci.yaml`: on push and pull request, with read-only `contents`
  permission. Steps: pin Flutter 3.47.x with pub cache, run `flutter pub get` at the
  root, `dart format --output=none --set-exit-if-changed .`, `flutter analyze`,
  `flutter test` in `apps/mobile`, and `dart test` in `packages/zema_core`.
- `apps/mobile/test/widget_test.dart` is replaced by `test/app_test.dart`, a smoke test
  that pumps `ZemaApp`.
- `packages/zema_core/test/zema_core_test.dart`: one trivial passing test.

**002 – App identity**
- `android:label="Zema"` in `AndroidManifest.xml`. Also check that `applicationId` and
  `namespace` are `com.zemaapp.zema` (they already are, so no change).
- iOS: `CFBundleDisplayName` is already `Zema`, so only check it.
- `apps/mobile/assets/icon/icon.png` (1024×1024): the ዜ glyph in `#E3AE4A` on
  `#110D0B`. Plus `icon_foreground.png`, a transparent foreground used for the adaptive
  icon and the Android 13+ monochrome layer.
- `flutter_launcher_icons` dev dependency, configured in `pubspec.yaml`. It generates the
  Android mipmaps, the adaptive icon (background `#110D0B`) with a monochrome layer, and
  the iOS AppIcon set.

**003 – Theme tokens and palettes**
- `lib/app/theme/zema_palette.dart`: `enum ZemaPalette { nightVigil, wine }` mapped to
  `ZemaColors`.
- `lib/app/theme/zema_colors.dart`: a `ThemeExtension<ZemaColors>` with all 15 tokens
  (bg … shadow), `const` instances for both palettes, `copyWith`, `lerp`, and a
  `context.zemaColors` getter. The getter asserts with a clear message when no theme
  is present.
- `lib/app/theme/zema_spacing.dart`: radius (12 / 16 / 24 / pill), side padding, list
  row height of 66 and minimum tap size of 44.
- `lib/app/theme/zema_theme.dart`: `buildTheme(ZemaPalette)` returns a dark
  `ThemeData`. Its `ColorScheme.dark` maps surface→bg, primary, onPrimary, plus
  onSurface, outline and the other sensible mappings. It sets `scaffoldBackgroundColor`,
  the text theme from the design-system typography table, and the `ZemaColors`
  extension.
- `lib/app/zema_app.dart`: `ZemaApp` (`MaterialApp`, Night Vigil by default) with a
  temporary placeholder home that shows "Zema / ዜማ / ስብሐት ለእግዚአብሔር". Navigation and
  Riverpod come in bolt 2, so the palette is passed as a plain constructor parameter
  until then.
- `lib/main.dart`: registers font licenses and calls `runApp(ZemaApp())`.

**004 – Bundled fonts**
- `apps/mobile/assets/fonts/`: Inter and Noto Sans Ethiopic at 400, 500, 600 and 700
  (static TTFs), plus `OFL-Inter.txt` and `OFL-NotoSansEthiopic.txt`. These are
  downloaded once from the official upstream releases (rsms/inter, notofonts/ethiopic)
  and committed.
- `pubspec.yaml` declares the `Inter` and `NotoSansEthiopic` families with weights.
- In the theme: `fontFamily: 'Inter'` and `fontFamilyFallback: ['NotoSansEthiopic']`.
  An exported `ethiopicTextHeight` constant of 1.5 sets line height in the text styles
  (≥ 1.4).
- `lib/app/licenses.dart`: `registerFontLicenses()`, called from `main()`, which uses
  `LicenseRegistry.addLicense` to read the bundled OFL texts.

### Dependencies

- **Flutter 3.47.7 / Dart 3.13** are installed locally and pinned to 3.47.x in CI.
- **flutter_launcher_icons** (dev) generates the placeholder icon set.
- **Network access, once**, to download the font TTFs and OFL texts. They are committed
  afterwards, and the app never fetches them at runtime.
- **A GitHub remote** to confirm CI is green. There is no remote yet, so CI is checked
  locally by running the same commands.
- The placeholder icon PNG is drawn by a small throwaway Dart script that renders ዜ
  with the bundled Noto Sans Ethiopic. It runs as a test-style script and is not
  committed (only the PNG output is).

### Technical Approach

- Folder layout follows `standards/coding-standards.md`: `lib/app/theme/`, with
  `lib/features/` and `lib/shared/` added in later bolts.
- The token hex values are typed once, in `zema_colors.dart`. The token test carries its
  own copy of the expected values taken from `docs/design-system.md`, so a typo in
  either place fails the test.
- The no-color-literal check is a test that walks `lib/` and fails on any `Color(0x`
  outside `lib/app/theme/`.
- The Ethiopic render test loads the bundled fonts into the test engine with
  `FontLoader`, then checks that ዜማ lays out with non-zero width per glyph and the
  expected line height. Golden tests are left out for now because goldens differ
  between macOS and the CI Linux runner.
- No Riverpod, go_router, l10n or shared_preferences yet. Those belong to bolts 2 and 3.

### Acceptance Criteria

- [ ] `flutter analyze` (mobile) and `dart analyze` (zema_core) report zero issues with
      the strict rules on
- [ ] `dart format --output=none --set-exit-if-changed .` passes at the repo root
- [ ] `.github/workflows/ci.yaml` runs pub get, format, analyze and both test suites
      with Flutter 3.47.x and read-only permissions
- [ ] The counter test is replaced by an app smoke test; zema_core has ≥ 1 passing test
- [ ] Android launcher label is "Zema"; `applicationId`/`namespace` are
      `com.zemaapp.zema`; iOS display name is "Zema"
- [ ] Placeholder ዜ icon (gold on `#110D0B`) generated, including adaptive and monochrome
      layers
- [ ] `ZemaColors` has 15 tokens; a unit test checks all 30 palette values
- [ ] `buildTheme` returns a dark theme with the ColorScheme mapping and the
      `ZemaColors` extension; `lerp` works
- [ ] No `Color(0x` literals outside `lib/app/theme/` (enforced by a test)
- [ ] Night Vigil is the default palette
- [ ] Inter and Noto Sans Ethiopic are bundled; Ethiopic falls back correctly; line height ≥ 1.4
- [ ] Both OFL licenses are registered in `LicenseRegistry`
- [ ] App launches to the themed placeholder showing Latin and Ethiopic text
