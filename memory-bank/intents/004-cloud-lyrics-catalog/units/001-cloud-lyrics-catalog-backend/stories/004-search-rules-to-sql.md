---
id: 004-search-rules-to-sql
unit: 001-cloud-lyrics-catalog-backend
intent: 004-cloud-lyrics-catalog
status: complete
priority: must
created: '2026-10-29T05:59:04Z'
assigned_bolt: 020-cloud-lyrics-catalog-backend
implemented: true
---

# Story: 004-search-rules-to-sql

## User Story

**As a** developer
**I want** the server to fold spellings exactly like the app
**So that** search finds the same songs everywhere

## Acceptance Criteria

- [x] **Given** `zema_core`'s rule tables, **When** the generator runs, **Then** it writes a SQL migration with the folding tables and a `zema_normalize`/`zema_skeleton` function pair
- [x] **Given** the generated functions, **When** applied to the 003 normalization test inputs, **Then** they return the same output as `zema_core` (parity test)
- [x] **Given** the rule tables change, **When** the generator is not re-run, **Then** a check in the Dart tests fails

## Technical Notes

- Generator in `packages/zema_core/tool/`; output committed under `backend/supabase/migrations/`.

## Dependencies

### Requires
- 001-local-supabase-and-schema

### Enables
- 005-server-search

## Edge Cases

| Scenario | Expected Behavior |
|----------|-------------------|
| Ethiopic punctuation and Latin noise words | Handled the same as in the app |

## Out of Scope

- Changing the rules themselves
