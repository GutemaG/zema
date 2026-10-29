---
id: 003-lyrics-cache
unit: 002-cloud-lyrics-catalog-ui
intent: 004-cloud-lyrics-catalog
status: draft
priority: must
created: 2026-10-29T05:59:04Z
assigned_bolt: 024-cloud-lyrics-catalog-ui
implemented: false
---

# Story: 003-lyrics-cache

## User Story

**As a** listener
**I want** lyrics to download once and then work offline
**So that** I can sing along anywhere

## Acceptance Criteria

- [ ] **Given** a linked or opened song, **When** its lyrics are needed, **Then** they are fetched, saved in Drift and shown; later opens read the cache
- [ ] **Given** a newer version on the server, **When** the index shows it, **Then** the cached song refreshes on next use
- [ ] **Given** no network and an uncached song, **When** opened, **Then** a C07 offline state with Retry shows
- [ ] **Given** the app, **When** built, **Then** it no longer bundles sample lyrics; tests use them as fixtures
- [ ] **Given** a cached song, **When** opened, **Then** lyrics show in < 300 ms

## Technical Notes

- A `CatalogLyricsRepository` (index + cache + zema_data) replaces `BundledLyricsRepository` behind `lyricsRepositoryProvider`.

## Dependencies

### Requires
- 002-song-index

### Enables
- 005-offline-downloads
- 006-report-wrong-lyrics
- 007-recordings-tab

## Edge Cases

| Scenario | Expected Behavior |
|----------|-------------------|
| Fetch fails half-way | Nothing partial is cached |

## Out of Scope

- Download all (005)
