---
id: 006-seed-script
unit: 001-cloud-lyrics-catalog-backend
intent: 004-cloud-lyrics-catalog
status: complete
priority: must
created: '2026-10-29T05:59:04Z'
assigned_bolt: 021-cloud-lyrics-catalog-backend
implemented: true
---

# Story: 006-seed-script

## User Story

**As a** developer
**I want** to load songs from files into the backend
**So that** the catalog starts with real data in the formats we already use

## Acceptance Criteria

- [x] **Given** `backend/seed/` with an index and LRC files, **When** the seed script runs against the local backend, **Then** the songs, sections, play order, recordings and timings are inserted as approved
- [x] **Given** the seed ran before, **When** it runs again, **Then** nothing changes (idempotent by song ID and version)
- [x] **Given** the three placeholder songs, **When** read back, **Then** they match the bundled versions (IDs, sections, play order, timings) in a test
- [x] **Given** a malformed file, **When** seeding, **Then** it is skipped and reported, and the rest load

## Technical Notes

- Dart script reusing `importLrc`; uses the local service key from `supabase status`, never committed. Placeholder songs move from `apps/mobile/assets/lyrics/` to `backend/seed/`.

## Dependencies

### Requires
- 001-local-supabase-and-schema

### Enables
- 001-zema-data-package (ui)

## Edge Cases

| Scenario | Expected Behavior |
|----------|-------------------|
| Song removed from the seed folder | Not deleted from the backend (seed only adds or updates) |

## Out of Scope

- Importing third-party lyrics
