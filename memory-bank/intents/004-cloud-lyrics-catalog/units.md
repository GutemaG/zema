---
intent: 004-cloud-lyrics-catalog
phase: inception
status: units-decomposed
updated: 2026-10-29T05:59:04Z
---

# Cloud Lyrics Catalog - Unit Decomposition

## Units Overview

The project type is `frontend-app`, but this intent adds the first backend, so it
decomposes into **2 units**: a backend unit (Supabase schema, rules, search, seed),
built and tested on its own against a local database, and the frontend unit
(`zema_data` plus the app), which depends on it. Both use the simple construction
bolt; the backend is SQL and scripts, not a domain model that needs DDD stages.

### Unit 1: 001-cloud-lyrics-catalog-backend

**Description**: The local Supabase project: schema migrations, Row Level Security, the
report function, search rules generated from `zema_core` and the search function, and
the seed script with the three placeholder songs.

**Stories**:

- 001-local-supabase-and-schema
- 002-row-level-security
- 003-report-function
- 004-search-rules-to-sql
- 005-server-search
- 006-seed-script

**Deliverables**:

- `backend/supabase/` (config, migrations, pgTAP tests)
- `backend/seed/` (index + LRC files) and the seed script (Dart, reusing `importLrc`)
- `packages/zema_core/tool/` generator for the SQL search rules

**Dependencies**:

- Depends on: `zema_core` (intent 003: models, LRC import, search tables)
- Depended by: `002-cloud-lyrics-catalog-ui`

**Estimated Complexity**: M

### Unit 2: 002-cloud-lyrics-catalog-ui

**Description**: `packages/zema_data`, the song index and lyrics cache in Drift, the
app switched from bundled lyrics to the catalog, Search merging the phone and the
catalog, offline download settings, report wrong lyrics, the Recordings tab and the Home
community row.

**Stories**:

- 001-zema-data-package
- 002-song-index
- 003-lyrics-cache
- 004-search-merge
- 005-offline-downloads
- 006-report-wrong-lyrics
- 007-recordings-tab
- 008-home-community-row

**Deliverables**:

- `packages/zema_data/` (new workspace package)
- `apps/mobile/lib/features/lyrics/` (catalog repository, index, cache), Drift schema v3
- Search, Song detail, Settings and Home changes; ARB strings in en
- Unit, Drift, widget and integration tests; emulator checks against the local backend

**Dependencies**:

- Depends on: `001-cloud-lyrics-catalog-backend`, intents 001–003
- Depended by: intents 005 (accounts), 006 (contributions)

**Estimated Complexity**: L

## Requirement-to-Unit Mapping

- **FR-1** Backend project and schema → `001-cloud-lyrics-catalog-backend` (story 001)
- **FR-2** Row Level Security (incl. the report insert path) → `001-cloud-lyrics-catalog-backend` (002, 003)
- **FR-3** Server-side search → `001-cloud-lyrics-catalog-backend` (004, 005)
- **FR-4** Seed script → `001-cloud-lyrics-catalog-backend` (006)
- **FR-5** `zema_data` package → `002-cloud-lyrics-catalog-ui` (001)
- **FR-6** Song index → `002-cloud-lyrics-catalog-ui` (002)
- **FR-7** Lyrics cache and offline → `002-cloud-lyrics-catalog-ui` (003, 005)
- **FR-8** Report wrong lyrics → `002-cloud-lyrics-catalog-ui` (006)
- **FR-9** Recordings tab → `002-cloud-lyrics-catalog-ui` (007)
- **FR-10** Home community row → `002-cloud-lyrics-catalog-ui` (008)
- **FR-11** Search merge → `002-cloud-lyrics-catalog-ui` (004)

## Unit Dependency Graph

```text
[zema_core] (intent 003, complete)
     │
     ▼
[001-cloud-lyrics-catalog-backend]
     │
     ▼
[002-cloud-lyrics-catalog-ui]
```

## Execution Order

Small bolts (1–2 stories) so each finishes in one session:

1. Bolt 018: local Supabase + schema (backend 001)
2. Bolt 019: Row Level Security + report function (backend 002–003)
3. Bolt 020: search rules to SQL + server search (backend 004–005)
4. Bolt 021: seed script (backend 006)
5. Bolt 022: `zema_data` package (ui 001)
6. Bolt 023: song index in Drift (ui 002)
7. Bolt 024: lyrics cache; app reads the catalog (ui 003)
8. Bolt 025: Search merges phone and catalog (ui 004)
9. Bolt 026: offline downloads in Settings (ui 005)
10. Bolt 027: report wrong lyrics + Recordings tab (ui 006–007)
11. Bolt 028: Home community row + intent checks (ui 008)
