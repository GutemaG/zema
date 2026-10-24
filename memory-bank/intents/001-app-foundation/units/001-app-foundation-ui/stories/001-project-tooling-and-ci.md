---
id: 001-project-tooling-and-ci
unit: 001-app-foundation-ui
intent: 001-app-foundation
status: complete
priority: must
created: 2026-10-23T22:22:46Z
assigned_bolt: 001-app-foundation-ui
implemented: true
---

# Story: 001-project-tooling-and-ci

## User Story

**As a** developer
**I want** strict analysis, a format check and CI running all tests on every push and PR
**So that** every stage stays analyzer-clean and releasable

## Acceptance Criteria

- [ ] **Given** `apps/mobile` and `packages/zema_core`, **When** I run `flutter analyze` / `dart analyze`, **Then** the strict rules from `standards/coding-standards.md` are active (strict-casts, strict-inference, strict-raw-types, prefer_const_*, require_trailing_commas, always_declare_return_types, unawaited_futures, avoid_print) and report zero issues
- [ ] **Given** a push or pull request, **When** CI runs, **Then** it executes `flutter pub get` at the workspace root, `dart format --output=none --set-exit-if-changed .`, `flutter analyze`, `flutter test` in `apps/mobile` and `dart test` in `packages/zema_core`
- [ ] **Given** an unformatted file, **When** CI runs, **Then** the job fails
- [ ] **Given** the default counter `widget_test.dart`, **When** this story is done, **Then** it is replaced by a smoke test that pumps the app and finds the app root
- [ ] **Given** `packages/zema_core` has no logic yet, **When** `dart test` runs, **Then** at least one test passes (no "no tests found" failure)

## Technical Notes

- Pure-Dart package uses `package:lints/recommended.yaml` as base; app uses `flutter_lints`.
- Exclude generated code (`**/*.g.dart`, l10n output) from analysis.
- Pin Flutter 3.47 in CI (`subosito/flutter-action` or equivalent) and cache pub.

## Dependencies

### Requires
- None (first story)

### Enables
- All other stories (CI guards them)

## Edge Cases

| Scenario | Expected Behavior |
|----------|-------------------|
| PR from a fork | Workflow runs with read-only permissions; no secrets needed |
| Workspace member added later | Root `flutter pub get` still resolves; CI needs only a new test step |

## Out of Scope

- Release builds/signing, deployment workflows
