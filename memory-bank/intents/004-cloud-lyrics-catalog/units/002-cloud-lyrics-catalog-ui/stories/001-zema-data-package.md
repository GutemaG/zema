---
id: 001-zema-data-package
unit: 002-cloud-lyrics-catalog-ui
intent: 004-cloud-lyrics-catalog
status: complete
priority: must
created: '2026-10-29T05:59:04Z'
assigned_bolt: 022-cloud-lyrics-catalog-ui
implemented: true
---

# Story: 001-zema-data-package

## User Story

**As a** developer
**I want** one package that talks to the catalog
**So that** the app and later the admin site share it

## Acceptance Criteria

- [x] **Given** the workspace, **When** built, **Then** `packages/zema_data` is a pure-Dart member depending on `zema_core` and `supabase`
- [x] **Given** the local backend, **When** calling it, **Then** it fetches the song index, one song with recordings and timings, search results, and submits a report
- [x] **Given** the backend is down or a request times out (10 s), **When** called, **Then** it returns a `ZemaFailure` (network, not found, rate limited), never a raw exception
- [x] **Given** the app, **When** built, **Then** the backend URL and anon key come from `--dart-define` with local defaults for the emulator (`10.0.2.2`)

## Technical Notes

- Integration tests run against the local backend and are skipped with a clear message when it is not running.

## Dependencies

### Requires
- 006-seed-script (backend)

### Enables
- 002-song-index
- 003-lyrics-cache

## Edge Cases

| Scenario | Expected Behavior |
|----------|-------------------|
| Wrong anon key | Failure with a clear message, not a crash |

## Out of Scope

- Auth sessions
