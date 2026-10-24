---
unit: 001-app-foundation-ui
intent: 001-app-foundation
unit_type: frontend
default_bolt_type: simple-construction-bolt
phase: inception
status: complete
created: 2026-10-23T22:22:46Z
updated: 2026-10-24T19:13:04Z
---

# Unit Brief: App Foundation UI

## Purpose

Turn the default Flutter template in `apps/mobile` into the real Zema app shell: themed
from design tokens, navigable across four tabs, translatable into four languages, with a
minimal persisted Settings screen and CI guarding quality. Later intents only add
features into this shell.

## Scope

### In Scope
- Analyzer/format config and GitHub Actions CI for the workspace
- App label, application ID check, placeholder launcher icon
- `ZemaColors` ThemeExtension (Night Vigil, Wine; each dark and light), light and dark `ThemeData`, spacing/radius constants
- Bundled Inter + Noto Sans Ethiopic with fallback and license registration
- ARB localization (en, am, om, ti), first-launch locale resolution, `om` fallback delegates
- go_router stateful shell with Home/Search/Library/Contribute and `/settings`, Riverpod root
- Shared C07 empty/error/offline component; "Coming soon" on all four tabs
- Settings screen (General: Language, Appearance; About: version, licenses)
- Theme mode System / Light / Dark (story 011, added 2026-10-24)
- `SettingsRepository` on `shared_preferences`, preloaded before `runApp`

### Out of Scope
- Real data, audio, lyrics, Drift (intent 002+)
- Onboarding S01–S04 (intent 007), other S28 sections (later intents)
- Translating am/om/ti strings beyond what exists (English fallback is acceptable)
- Final launcher icon artwork

---

## Assigned Requirements

| FR | Requirement | Priority |
|----|-------------|----------|
| FR-1 | App shell with bottom navigation | Must |
| FR-2 | Placeholder tab content using shared empty state (C07) | Must |
| FR-3 | Theme from design tokens | Must |
| FR-4 | Palette switch with persistence | Must |
| FR-12 | Theme mode (System / Light / Dark) with persistence | Must |
| FR-5 | Bundled fonts | Must |
| FR-6 | Routing and state management | Must |
| FR-7 | Localization scaffold and initial locale | Must |
| FR-8 | Language switch with persistence | Must |
| FR-9 | Settings screen (S28, minimal) | Must |
| FR-10 | App identity | Must |
| FR-11 | Tooling and CI | Must |

---

## Domain Concepts

### Key Entities
| Entity | Description | Attributes |
|--------|-------------|------------|
| `ZemaPalette` | Which approved palette is active | `nightVigil` (default), `wine` |
| `ZemaColors` | ThemeExtension of design tokens | 15 tokens: bg … shadow |
| `AppLanguage` | Supported UI languages | `en`, `am`, `om`, `ti` + native display name |
| `AppSettings` | User's persisted preferences | `palette`, `themeMode` (System by default), `language` (nullable until chosen) |
| `EmptyStateKind` | C07 variant | `empty`, `error`, `offline` |

### Key Operations
| Operation | Description | Inputs | Outputs |
|-----------|-------------|--------|---------|
| `resolveInitialLanguage` | Pick UI language on launch | saved language?, device locales | `AppLanguage` |
| `SettingsRepository.load` | Read prefs before first frame | — | `AppSettings` (defaults on missing/invalid) |
| `SettingsRepository.savePalette / saveLanguage` | Persist a change | value | — |
| `buildTheme` | Build `ThemeData` from palette and brightness | `ZemaPalette`, `Brightness` | `ThemeData` |

---

## Story Summary

| Metric | Count |
|--------|-------|
| Total Stories | 11 |
| Must Have | 11 |
| Should Have | 0 |
| Could Have | 0 |

### Stories

| Story ID | Title | Priority | Status |
|----------|-------|----------|--------|
| 001-project-tooling-and-ci | Project tooling and CI | Must | Planned |
| 002-app-identity | App identity | Must | Planned |
| 003-theme-tokens-and-palettes | Theme tokens and palettes | Must | Planned |
| 004-bundled-fonts | Bundled Latin and Ethiopic fonts | Must | Planned |
| 005-localization-and-initial-locale | Localization and first-launch language | Must | Planned |
| 006-app-shell-and-routing | App shell, bottom navigation and routing | Must | Planned |
| 007-shared-empty-state-component | Shared empty/error/offline state (C07) | Must | Planned |
| 008-settings-screen | Minimal Settings screen | Must | Planned |
| 009-switch-palette | Switch and remember palette | Must | Planned |
| 010-switch-language | Switch and remember language | Must | Planned |
| 011-switch-theme-mode | Switch and remember theme mode (added during construction) | Must | Planned |

---

## Dependencies

### Depends On
| Unit | Reason |
|------|--------|
| — | First unit of the project |

### Depended By
| Unit | Reason |
|------|--------|
| All later frontend units (intents 002–007) | Shell, theme, l10n, C07, settings pattern |

### External Dependencies
| System | Purpose | Risk |
|--------|---------|------|
| GitHub Actions | CI | Low |
| Google Fonts / Noto (download once into repo) | Font files | Low |
| `flutter_localizations` (no Material `om`) | Built-in widget strings | Medium (mitigated by fallback delegate) |

---

## Technical Context

### Suggested Technology
Per `standards/tech-stack.md`: `flutter_riverpod`, `go_router`, `shared_preferences`,
`flutter_localizations` + `intl` with `generate: true` (gen-l10n), `package_info_plus`
for the version row, `flutter_launcher_icons` (dev) for the placeholder icon.

### Integration Points
| Integration | Type | Protocol |
|-------------|------|----------|
| shared_preferences | Local storage | Platform plugin |
| GitHub Actions | CI | YAML workflow |

### Data Storage
| Data | Type | Volume | Retention |
|------|------|--------|-----------|
| `paletteId`, `themeMode`, `localeCode` | Key-value (shared_preferences) | 3 keys | Until app data cleared |

---

## Constraints

- Settings must be loaded in `main()` and injected via `ProviderScope` overrides (no first-frame flash).
- No `Color(0x…)` literals outside `lib/app/theme/`.
- No user-visible string literals in widgets; everything through `AppLocalizations`.
- `packages/zema_core` must still build and pass `dart test` (add one trivial test if empty).

---

## Success Criteria

### Functional
- [ ] App launches on emulator and a real phone; four tabs switch and keep state
- [ ] Palette and language switches apply immediately and survive force-stop
- [ ] Ethiopic text renders with bundled font offline
- [ ] Settings shows Language, Appearance, version, licenses — nothing else

### Non-Functional
- [ ] Cold start < 2 s (release, mid-range phone)
- [ ] Zero network calls
- [ ] Touch targets ≥ 44×44; TalkBack labels on icon buttons
- [ ] No overflow at 1.3× text scale or +40% string length

### Quality
- [ ] `flutter analyze` zero issues; `dart format` clean
- [ ] Unit tests for token values, locale resolution, settings repository
- [ ] Widget tests for shell navigation, C07 variants, Settings
- [ ] CI green

---

## Bolt Suggestions

| Bolt | Type | Stories | Objective |
|------|------|---------|-----------|
| 001-app-foundation-ui | simple | 001, 002, 003, 004 | Tooling, identity, theme, fonts |
| 002-app-foundation-ui | simple | 005, 006, 007 | Localization, shell + routing, C07 |
| 003-app-foundation-ui | simple | 008, 009, 010, 011 | Settings + persistence + theme mode |

---

## Notes

- Existing state: `apps/mobile` is the default Flutter counter template (`lib/main.dart`, `test/widget_test.dart`); `analysis_options.yaml` includes `flutter_lints` with no extras; `applicationId` is already `com.zemaapp.zema`.
- Folder layout per `standards/coding-standards.md` (`lib/app`, `lib/features/*`, `lib/shared`).
