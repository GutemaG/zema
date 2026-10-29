---
unit: 001-cloud-lyrics-catalog-backend
intent: 004-cloud-lyrics-catalog
unit_type: backend
default_bolt_type: simple-construction-bolt
phase: inception
status: stories-defined
created: 2026-10-29T05:59:04Z
updated: 2026-10-29T05:59:04Z
---

# Unit Brief: Cloud Lyrics Catalog Backend

## Purpose

The first backend: a local Supabase project holding the shared lyrics catalog, with Row Level Security, a rate-limited report function, server search using rules generated from `zema_core`, and a seed script loading songs from files.

## Scope

### In Scope
- Supabase project in `backend/supabase/` (config, migrations, pgTAP tests)
- Schema: songs, sections, lines, play order, recordings, sync timings, reports, contributions, roles
- RLS: anonymous read of approved content only
- `submit_report` RPC, 5 per install per 24 h
- SQL search rules generated from `zema_core`; `search_songs` RPC
- Seed script + placeholder songs in `backend/seed/`

### Out of Scope
- Hosted project, auth, moderation tools
- Writing contributions (006)

---

## Assigned Requirements

| FR | Requirement | Priority |
|----|-------------|----------|
| FR-1 | Backend project and schema | Must |
| FR-2 | Row Level Security | Must |
| FR-3 | Server-side search | Must |
| FR-4 | Seed script | Must |

---

## Story Summary

| Metric | Count |
|--------|-------|
| Total Stories | 6 |
| Must Have | 5 |
| Should Have | 1 |
| Could Have | 0 |

### Stories

| Story ID | Title | Priority | Status |
|----------|-------|----------|--------|
| 001-local-supabase-and-schema | Local Supabase and catalog schema | Must | Complete |
| 002-row-level-security | Row Level Security | Must | Planned |
| 003-report-function | Rate-limited report function | Should | Planned |
| 004-search-rules-to-sql | Search rules generated into SQL | Must | Planned |
| 005-server-search | Server search function | Must | Planned |
| 006-seed-script | Seed script and placeholder songs | Must | Planned |

---

## Dependencies

### Depends On
| Unit | Reason |
|------|--------|
| `zema_core` (intent 003) | Models, LRC import, search rule tables |

### Depended By
| Unit | Reason |
|------|--------|
| 002-cloud-lyrics-catalog-ui | Reads the catalog, submits reports |
| Intents 005/006/008 | Roles, contributions, moderation |

---

## Technical Context

### Suggested Technology
Supabase CLI via `npx supabase` (Docker), Postgres + pgTAP, Dart for the seed script and SQL generator.

### Data Storage
| Data | Type | Volume | Retention |
|------|------|--------|-----------|
| Catalog | Postgres | 3 songs now, thousands later | Permanent |
| Reports | Postgres | Small | Until moderated |

---

## Constraints

- Only the anon key in the app; no service key committed anywhere.
- `zema_core` stays free of backend code.
- No `Color(0x…)` literals outside `lib/app/theme/`; no user-visible string literals.
- iOS build must keep compiling.

---

## Success Criteria

### Functional
- [ ] `supabase db reset` + `supabase test db` pass
- [ ] Anonymous role reads only approved content and cannot write
- [ ] Server search matches `zema_core` on the 003 queries
- [ ] Seeded songs match the bundled versions

### Non-Functional
- [ ] Analyze and format clean; all tests pass
