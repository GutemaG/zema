---
unit: 002-cloud-lyrics-catalog-ui
intent: 004-cloud-lyrics-catalog
unit_type: frontend
default_bolt_type: simple-construction-bolt
phase: inception
status: stories-defined
created: 2026-10-29T05:59:04Z
updated: 2026-10-29T08:32:46Z
---

# Unit Brief: Cloud Lyrics Catalog UI

## Purpose

Switch the app from bundled sample lyrics to the cloud catalog without losing offline use: `zema_data`, a song index and lyrics cache in Drift, Search over the phone and catalog, offline downloads, reports, the Recordings tab and a Home community row.

## Scope

### In Scope
- `packages/zema_data` (Supabase repository, pure Dart)
- Drift schema v3: song index, cached songs, queued reports
- Catalog-backed `lyricsRepositoryProvider`; bundled samples removed from the app
- Search merge with offline note
- Settings: storage, Download all, Clear
- Report wrong lyrics, Recordings tab, Home community row

### Out of Scope
- Sign-in, contributions, moderation
- Translating new strings into am/om/ti (English fallback)

---

## Assigned Requirements

| FR | Requirement | Priority |
|----|-------------|----------|
| FR-5 | `zema_data` package | Must |
| FR-6 | Song index on the phone | Must |
| FR-7 | Lyrics cache and offline | Must/Should |
| FR-8 | Report wrong lyrics | Should |
| FR-9 | Recordings tab | Should |
| FR-10 | Home community row | Could |
| FR-11 | Search merge | Must |

---

## Story Summary

| Metric | Count |
|--------|-------|
| Total Stories | 8 |
| Must Have | 4 |
| Should Have | 3 |
| Could Have | 1 |

### Stories

| Story ID | Title | Priority | Status |
|----------|-------|----------|--------|
| 001-zema-data-package | zema_data Supabase repository | Must | Complete |
| 002-song-index | Song index on the phone | Must | Complete |
| 003-lyrics-cache | Lyrics cache; the app reads the catalog | Must | Planned |
| 004-search-merge | Search merges the phone and the catalog | Must | Planned |
| 005-offline-downloads | Offline downloads in Settings | Should | Planned |
| 006-report-wrong-lyrics | Report wrong lyrics | Should | Planned |
| 007-recordings-tab | Song detail Recordings tab | Should | Planned |
| 008-home-community-row | Home: new lyrics from the community | Could | Planned |

---

## Dependencies

### Depends On
| Unit | Reason |
|------|--------|
| 001-cloud-lyrics-catalog-backend | Schema, RPCs, seed data |
| Intents 001–003 | Shell, library, lyrics features |

### Depended By
| Unit | Reason |
|------|--------|
| Intents 005/006 | Accounts and contributions build on the repository |

---

## Technical Context

### Suggested Technology
`supabase` Dart client in `zema_data` only; existing Riverpod, drift, go_router.

### Data Storage
| Data | Type | Volume | Retention |
|------|------|--------|-----------|
| Song index | Drift | ~5,000 rows | Refreshed ≤ 6 h |
| Cached lyrics | Drift | Viewed songs (or all) | Until cleared |
| Queued reports | Drift | A few | Until sent |
| Install ID | shared_preferences | 1 key | Until app data cleared |

---

## Constraints

- Only the anon key in the app; no service key committed anywhere.
- `zema_core` stays free of backend code.
- No `Color(0x…)` literals outside `lib/app/theme/`; no user-visible string literals.
- iOS build must keep compiling.

---

## Success Criteria

### Functional
- [ ] Linked sample songs show lyrics from the local backend on the emulator
- [ ] Offline after one view: lyrics still show
- [ ] Search finds a line from an uncached song online; offline note offline
- [ ] Analyze, format, tests and iOS build pass

### Non-Functional
- [ ] Analyze and format clean; all tests pass
