---
intent: 001-app-foundation
phase: inception
status: units-defined
created: 2026-10-23T22:16:40Z
updated: 2026-10-23T22:31:00Z
---

# Requirements: App Foundation

> Source: `docs/roadmap.md` Stage 1 · theme tokens and fonts: `docs/design-system.md` ·
> settings screen: `docs/screens.md` S28 · Complexity ★☆☆☆☆ · No backend, no native code.

## Intent Overview

An empty but real app: themed, navigable, translatable, and tested. Every later stage
builds on this shell, the theme, the localization setup and the shared empty-state
component created here.

## Business Goals

| Goal | Success Metric | Priority |
|------|----------------|----------|
| Installable app shell on Android | Launches on emulator and a real phone; four tabs switch | Must |
| Design system wired from tokens | Palette switch re-themes the whole UI immediately and survives restart | Must |
| Ethiopic-ready from day one | Ethiopic text renders with the bundled font, no fallback boxes | Must |
| Multilingual scaffold | Language switch updates the UI immediately and survives restart | Must |
| Guarded quality from the start | CI runs analyze, format check and tests on every push/PR | Must |

---

## Functional Requirements

### FR-1: App shell with bottom navigation
- **Description**: Bottom navigation with four tabs: Home, Search, Library, Contribute. Active tab uses `primaryText` and bold label; inactive uses `muted`. Each tab keeps its own navigation stack.
- **Acceptance Criteria**:
  - Tapping each tab shows that tab's screen.
  - Switching away from a tab and back preserves its scroll position/state.
  - Android back on a tab root exits the app (or returns to Home first if on another tab).
  - Each nav item's tap target is ≥ 44×44 and has a screen-reader label.
- **Priority**: Must

### FR-2: Placeholder tab content using shared empty state (C07)
- **Description**: Build the shared C07 empty/error/offline state component (icon, title, message, optional action button) and use it on all four tabs to show a localized "Coming soon" message. A gear icon on the Home header opens Settings.
- **Acceptance Criteria**:
  - C07 lives in `shared/` and supports empty, error and offline variants with an optional action callback.
  - All four tabs render C07 with localized text; no hard-coded strings.
  - Widget tests cover each C07 variant with and without an action.
- **Priority**: Must

### FR-3: Theme from design tokens
- **Description**: `ZemaColors` `ThemeExtension` containing every token in `docs/design-system.md` (bg, surface, line, text, muted, faint, primary, onPrimary, primaryText, accent, accentText, soft, tile, tileFg, shadow) with two instances: Night Vigil (default) and Night Vigil · Wine. `ThemeData` built from it with `ColorScheme.dark(...)`. Dark only. Spacing/radius values from the design system available as constants.
- **Acceptance Criteria**:
  - All 15 tokens exist with the exact hex values from `docs/design-system.md` for both palettes (unit test compares values).
  - No `Color(0x...)` literals outside the theme files (checked by grep in CI or a test).
  - Default palette on first launch is Night Vigil.
- **Priority**: Must

### FR-4: Palette switch with persistence
- **Description**: User selects Night Vigil or Night Vigil · Wine in Settings; choice stored with `shared_preferences`.
- **Acceptance Criteria**:
  - Selecting a palette re-themes all visible screens without restarting the app.
  - After force-stopping and relaunching, the chosen palette is applied on the first frame (no flash of the default palette).
- **Priority**: Must

### FR-5: Bundled fonts
- **Description**: Inter and Noto Sans Ethiopic bundled as assets; Inter is the primary family with Noto Sans Ethiopic as fallback. Ethiopic text styles use line height ≥ 1.4.
- **Acceptance Criteria**:
  - With network disabled on a fresh install, Ethiopic sample text (e.g. "ዜማ", "ስብሐት ለእግዚአብሔር") renders with no tofu boxes.
  - No runtime font downloads (no `google_fonts` network fetching).
  - Font licenses appear in About → Licenses.
- **Priority**: Must

### FR-6: Routing and state management
- **Description**: go_router with a stateful shell route for the four tabs and a `/settings` route; Riverpod `ProviderScope` at the root. Settings values exposed through providers.
- **Acceptance Criteria**:
  - Routes `/home`, `/search`, `/library`, `/contribute`, `/settings` each open the right screen.
  - Unknown routes show a C07 error state instead of crashing.
- **Priority**: Must

### FR-7: Localization scaffold and initial locale
- **Description**: `flutter_localizations` + ARB files for en, am, om, ti. English is complete; missing keys in other locales fall back to English. On first launch the app uses the device language if it is am, om or ti, otherwise English.
- **Acceptance Criteria**:
  - Device set to Amharic → first launch shows Amharic for keys that exist and English for the rest.
  - Device set to an unsupported language (e.g. French) → first launch is English.
  - A test fails if any widget under `lib/` uses a string literal for user-visible text (or analyzer rule/ARB key check equivalent).
- **Priority**: Must

### FR-8: Language switch with persistence
- **Description**: User selects English, አማርኛ, Afaan Oromoo or ትግርኛ (each shown in its own language) in Settings; choice stored with `shared_preferences` and overrides the device language from then on.
- **Acceptance Criteria**:
  - Changing language updates all visible strings immediately without restart.
  - The choice survives force-stop and relaunch.
- **Priority**: Must

### FR-9: Settings screen (S28, minimal)
- **Description**: Settings screen styled per the design system (grouped cards, value rows with ›), containing only: General → Language, Palette; About → version, open-source licenses.
- **Acceptance Criteria**:
  - Language and Palette rows show the current value and open a picker.
  - About shows the app version from the build (e.g. `1.0.0 (1)`) and opens Flutter's license page.
  - No other S28 sections are present.
- **Priority**: Must

### FR-10: App identity
- **Description**: App label "Zema", application ID `com.zemaapp.zema`, placeholder launcher icon (ዜ on `bg` with `primary` glyph, or similar).
- **Acceptance Criteria**:
  - Installed app shows the label "Zema" and the placeholder icon on the launcher.
  - `applicationId` is `com.zemaapp.zema`.
- **Priority**: Must

### FR-11: Tooling and CI
- **Description**: `analysis_options.yaml` per `standards/coding-standards.md` in `apps/mobile` and `packages/zema_core`; GitHub Actions workflow that runs `flutter pub get` at the workspace root, `dart format` check, `flutter analyze`, `flutter test` (mobile) and `dart test` (zema_core) on push and pull request.
- **Acceptance Criteria**:
  - `flutter analyze` reports zero issues locally and in CI.
  - All tests pass locally and in CI.
  - CI fails on unformatted code.
  - The default `widget_test.dart` counter test is replaced by real tests.
- **Priority**: Must

---

## Non-Functional Requirements

### NFR-1: Performance
| Requirement | Metric | Target |
|-------------|--------|--------|
| Cold start | Launch → first frame, release build, mid-range phone | < 2 s |
| Theme/language switch | Time to re-render | Same frame as the selection (no restart, no visible flicker) |

### NFR-2: Offline
| Requirement | Metric | Target |
|-------------|--------|--------|
| Network use | Network calls made by the app in 001 | 0 |

### NFR-3: Accessibility
| Requirement | Standard | Notes |
|-------------|----------|-------|
| Touch targets | ≥ 44×44 | Nav items, settings rows, picker options |
| Contrast | ≥ 4.5:1 | `text`/`muted` on `bg`/`surface` in both palettes |
| Screen reader | TalkBack | Every icon-only button has a semantic label |
| Text scale | System font scale up to 1.3× | No overflow errors on Settings and tab screens |

### NFR-4: Localization robustness
| Requirement | Metric | Target |
|-------------|--------|--------|
| Long strings | Settings and nav with pseudo-long (≈ +40%) strings | No overflow errors |
| Ethiopic layout | Line height for Ge'ez text | ≥ 1.4 |

---

## Constraints

### Technical Constraints

**Project-wide standards**: Required standards will be loaded from memory-bank standards folder by Construction Agent

**Intent-specific constraints**:
- Settings persistence uses `shared_preferences` (decided 2026-10-23); no Drift in this intent.
- Settings must be loaded before the first frame (e.g. read in `main()` and passed to `ProviderScope` overrides) to avoid a palette/language flash.
- `zema_core` gets no domain code in this intent beyond what tests/CI need; it must still build and pass `dart test`.

### Business Constraints
- **Out of scope:** any real data, audio, lyrics, onboarding screens (S01–S04), other S28 sections, iOS-specific work beyond "it builds".

---

## Assumptions

| Assumption | Risk if Invalid | Mitigation |
|------------|-----------------|------------|
| Font licenses (SIL OFL) allow bundling | Legal issue | Both are OFL; register licenses in `LicenseRegistry` |
| Dark-only theme is acceptable | Rework if light theme requested later | Tokens isolated in `ZemaColors`; a new palette is additive |
| Flutter's built-in localizations cover am and ti; om may not exist | Material widgets show English/crash for om | Provide fallback delegate mapping `om` Material/Cupertino strings to English |

---

## Open Questions

| Question | Owner | Due Date | Resolution |
|----------|-------|----------|------------|
| Final launcher icon artwork | Product owner | Before first release | Pending (placeholder in 001) |
| Settings store | Product owner | 2026-10-23 | Resolved: `shared_preferences` |
| First-launch language | Product owner | 2026-10-23 | Resolved: device language if am/om/ti, else English |
| Placeholder content | Product owner | 2026-10-23 | Resolved: shared C07 component built now |
| CI required? | Product owner | 2026-10-23 | Resolved: Must |
