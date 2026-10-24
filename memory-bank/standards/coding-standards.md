# Coding Standards

## Overview

Standard Dart style enforced by the formatter and a strict analyzer. Business logic goes
in pure-Dart `zema_core` and is unit-tested; UI stays thin. Every stage must end
analyzer-clean and releasable.

## Code Formatting

**Tool**: `dart format`
**Key Settings**:
- Line length: 80 (default)
- Trailing commas on multi-line argument/parameter lists (lets the formatter keep
  widget trees vertical)

**Enforcement**: format on save; CI fails on `dart format --output=none --set-exit-if-changed .`

## Linting

**Tool**: Dart analyzer
**Base Config**: `package:flutter_lints/flutter.yaml` (apps), `package:lints/recommended.yaml` (pure-Dart packages)
**Strictness**: strict

**Key Rules** (in every `analysis_options.yaml`):
- `analyzer.language`: `strict-casts`, `strict-inference`, `strict-raw-types`: no
  implicit `dynamic`
- `prefer_const_constructors`, `prefer_const_declarations`: cheaper rebuilds on low-end phones
- `require_trailing_commas`: stable formatting of widget trees
- `always_declare_return_types`: readable public APIs
- `unawaited_futures`: no silently dropped async work (playback, DB writes)
- `avoid_print`: use the logger

Generated files (`*.g.dart`, `*.freezed.dart`, `lib/l10n/` output) are excluded from
analysis.

## Naming Conventions

| Element | Convention | Example |
|---------|------------|---------|
| Classes, enums, typedefs, extensions | UpperCamelCase | `SyncTiming`, `PlaybackState` |
| Variables, functions, parameters | lowerCamelCase | `currentLineIndex` |
| Constants | lowerCamelCase | `defaultMinDuration` |
| Riverpod providers | lowerCamelCase + `Provider` | `libraryTracksProvider` |
| Repository interfaces / implementations | `XRepository` / `<Impl>XRepository` | `LyricsRepository`, `SupabaseLyricsRepository`, `FakeLyricsRepository` |
| Design tokens | names from `docs/design-system.md`, as-is | `ZemaColors.primaryText` |
| ARB keys | lowerCamelCase, screen-prefixed | `settingsLanguageTitle` |
| Kotlin classes | UpperCamelCase | `NowPlayingListenerService` |
| Platform channels | reverse-DNS | `com.zemaapp.zema/now_playing` |

**File Naming**:
- Dart files: `snake_case.dart`, one public widget/class per file where practical
- Tests: `<file>_test.dart`, mirroring the `lib/` path
- Screens: `<name>_screen.dart`; reusable widgets: `<name>.dart` under `widgets/`

## File Organization

**Pattern**: feature-based in the app; domain-based in `zema_core`

**Structure**:
```text
apps/mobile/lib/
  main.dart
  app/            app widget, router, theme (ZemaColors), l10n setup
  features/
    library/      data/ (Drift DAOs, scanner) · application/ (providers) · presentation/ (screens, widgets)
    player/
    lyrics/
    search/
    home/
    contribute/
    account/
    detection/    platform-channel client for Kotlin listener + overlay
    settings/
  shared/         widgets used by several features (C01–C09), utils
apps/mobile/android/app/src/main/kotlin/com/zemaapp/zema/   native listener / overlay
packages/zema_core/lib/
  zema_core.dart  public exports only
  src/            models/, lyrics/, sync/, search/, matching/, repositories/ (interfaces)
packages/zema_data/  Supabase implementations of zema_core repositories (stage 4+)
backend/          migrations/, policies/, seed/
```

**Conventions**:

- Tests: `test/` in each package, mirroring `lib/`
- Models: immutable classes with `==`/`hashCode` and `copyWith` (in `zema_core/src/models`)
- Index files: only the package barrel (`zema_core.dart`); no barrels inside features
- Feature code must not import another feature's `data/` layer; share via `zema_core` or `shared/`
- No hard-coded UI strings: everything goes through ARB/`AppLocalizations`

## Testing Strategy

**Framework**: `package:test` (`zema_core`), `flutter_test` (app widgets), `integration_test` for device flows
**Coverage Target**: all logic in `zema_core` (sync engine, play order, normalization, matching, validation) unit-tested; widgets covered for key states

**Test Types**:

| Type | Tool | When to Use |
|------|------|-------------|
| Unit | `dart test` | All `zema_core` logic; Riverpod notifiers with fakes |
| Widget | `flutter test` | Screens/components in each state (loading, empty, error, data) and with Ethiopic text |
| Database | Drift in-memory `NativeDatabase.memory()` | DAOs and migrations |
| Integration | `integration_test` on device | Playback in background, permission flows, detection → overlay |
| Backend | SQL tests / Supabase local | RLS policies (read approved only, own backup only, moderator writes) |

**Conventions**:

- Test naming: `group('<Unit>')` + `test('<does X> when <condition>')`
- Test structure: Arrange / Act / Assert
- Mock strategy: prefer hand-written fakes implementing repository interfaces
  (`FakeLyricsRepository`); `mocktail` only where a fake is impractical
- Include Ethiopic fixtures (ሀ/ሐ/ኀ variants, transliteration) in search/matching tests

## Error Handling

**Pattern**: typed failures at repository boundaries; exceptions inside

- Repositories return results or throw a sealed `ZemaFailure` subtype (`NetworkFailure`,
  `PermissionFailure`, `NotFoundFailure`, `ValidationFailure`), never raw
  platform/HTTP exceptions.
- Riverpod `AsyncValue` carries loading/error state to the UI. Screens show the shared
  C07 empty/error/offline states with a retry action.
- Offline is a normal state: fall back to cached data instead of showing an error.
- Validation rules (title required, ≥1 section, strictly increasing timestamps) live in
  `zema_core` and are shared by app, admin site and tests.
- Platform-channel calls catch `PlatformException` and map it to `PermissionFailure` or
  an unsupported-platform result (iOS).

**Custom Errors**: yes, the sealed `ZemaFailure` hierarchy in `zema_core`.

## Logging

**Tool**: `package:logging` (`Logger('feature.component')`); Kotlin side uses `android.util.Log` with tag `Zema`
**Format**: text, `[level] logger: message`; debug output only in debug builds

**Levels**:

| Level | Usage |
|-------|-------|
| `FINE` | Detection events, sync position ticks (debug only) |
| `INFO` | Library scan finished, match made, backup done |
| `WARNING` | Recoverable failures (network, missing permission) |
| `SEVERE` | Unexpected errors, failed DB migration |

**Privacy**: never log notification text, user tokens, or full file paths in release
builds. Media metadata (title/artist) only at `FINE`.
