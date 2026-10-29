---
id: 005-server-search
unit: 001-cloud-lyrics-catalog-backend
intent: 004-cloud-lyrics-catalog
status: complete
priority: must
created: '2026-10-29T05:59:04Z'
assigned_bolt: 020-cloud-lyrics-catalog-backend
implemented: true
---

# Story: 005-server-search

## User Story

**As a** listener
**I want** to search the whole catalog by title, artist or a lyric line
**So that** I find songs I don't have yet

## Acceptance Criteria

- [x] **Given** a query, **When** `search_songs` is called, **Then** approved songs matching title, transliteration, artist or a line are returned best first, each once, with the matching line
- [x] **Given** the 003 search test queries ("kidist", "ቅድስት", "ቅዱስት" …), **When** run on the server and in `zema_core` over the same songs, **Then** both return the same songs
- [x] **Given** 5,000 seeded songs, **When** searching, **Then** the function answers in < 200 ms on the local database

## Technical Notes

- Search keys stored per song/line (generated columns or triggers using the generated functions); trigram index for speed.

## Dependencies

### Requires
- 004-search-rules-to-sql

### Enables
- 004-search-merge (ui)

## Edge Cases

| Scenario | Expected Behavior |
|----------|-------------------|
| Empty or one-letter query | Empty result |

## Out of Scope

- Ranking tweaks beyond 003's scoring
