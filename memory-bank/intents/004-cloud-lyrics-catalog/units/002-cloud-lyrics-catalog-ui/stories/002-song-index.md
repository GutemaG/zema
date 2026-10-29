---
id: 002-song-index
unit: 002-cloud-lyrics-catalog-ui
intent: 004-cloud-lyrics-catalog
status: draft
priority: must
created: 2026-10-29T05:59:04Z
assigned_bolt: 023-cloud-lyrics-catalog-ui
implemented: false
---

# Story: 002-song-index

## User Story

**As a** listener
**I want** my songs to link to catalog lyrics even offline
**So that** lyrics are ready when I play

## Acceptance Criteria

- [ ] **Given** the app starts online and the index is older than 6 h (or missing), **When** it starts, **Then** the index refreshes in the background into Drift (schema v3)
- [ ] **Given** no network, **When** the app runs, **Then** automatic linking and title search use the last index
- [ ] **Given** a song removed from the catalog, **When** the index refreshes, **Then** it drops out and tracks linked to it show "No lyrics", not an error
- [ ] **Given** Search, **When** I pull to refresh, **Then** the index refreshes and a failure shows a short message

## Technical Notes

- Drift v2 → v3 migration with a test; links to the old bundled IDs keep working because IDs are unchanged.

## Dependencies

### Requires
- 001-zema-data-package

### Enables
- 003-lyrics-cache
- 004-search-merge
- 008-home-community-row

## Edge Cases

| Scenario | Expected Behavior |
|----------|-------------------|
| First launch offline | Empty index; the app works, lyrics show "No lyrics" until online |

## Out of Scope

- Delta sync
