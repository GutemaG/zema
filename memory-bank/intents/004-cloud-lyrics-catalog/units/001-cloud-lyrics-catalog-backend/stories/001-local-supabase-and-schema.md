---
id: 001-local-supabase-and-schema
unit: 001-cloud-lyrics-catalog-backend
intent: 004-cloud-lyrics-catalog
status: draft
priority: must
created: 2026-10-29T05:59:04Z
assigned_bolt: 018-cloud-lyrics-catalog-backend
implemented: false
---

# Story: 001-local-supabase-and-schema

## User Story

**As a** developer
**I want** a local Supabase project with the catalog schema in migrations
**So that** the backend is versioned, reproducible and testable

## Acceptance Criteria

- [ ] **Given** Docker, **When** I run `supabase start` and `supabase db reset` in `backend/`, **Then** the database builds from migrations with no errors
- [ ] **Given** the schema, **When** inspected, **Then** it has songs (slug ID, title, transliteration, artist, album, status, version, approved_at), sections, lines, play order, recordings, sync timings, reports, contributions and user roles
- [ ] **Given** a song, **When** its sections or timings change, **Then** its version increases (so phones know to refresh their cache)
- [ ] **Given** pgTAP, **When** `supabase test db` runs, **Then** a schema test lists the expected tables and key constraints

## Technical Notes

- Supabase CLI via `npx supabase` (no global install); `backend/README.md` explains start/reset/test.
- Status values: draft, approved, rejected. Contributions and roles tables exist but nothing writes them yet (005/006).

## Dependencies

### Requires
- None

### Enables
- 002-row-level-security
- 006-seed-script

## Edge Cases

| Scenario | Expected Behavior |
|----------|-------------------|
| Docker not running | README says so; nothing else depends on it |

## Out of Scope

- Hosted project, auth
