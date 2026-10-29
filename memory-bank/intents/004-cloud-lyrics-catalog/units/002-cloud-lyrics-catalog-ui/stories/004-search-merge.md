---
id: 004-search-merge
unit: 002-cloud-lyrics-catalog-ui
intent: 004-cloud-lyrics-catalog
status: draft
priority: must
created: 2026-10-29T05:59:04Z
assigned_bolt: 025-cloud-lyrics-catalog-ui
implemented: false
---

# Story: 004-search-merge

## User Story

**As a** listener
**I want** to find songs from the catalog in Search
**So that** I find lyrics even for songs I don't have

## Acceptance Criteria

- [ ] **Given** a query, **When** searching, **Then** phone results show at once and catalog title matches come from the index
- [ ] **Given** online, **When** searching, **Then** lyric-line matches come from the server (debounced 300 ms) and a line from an uncached song is found
- [ ] **Given** offline, **When** searching, **Then** the Lyrics group shows a C07 offline note and lines from cached songs; phone results are unaffected
- [ ] **Given** a 3G-class network, **When** searching, **Then** catalog results arrive in < 1 s

## Technical Notes

- Local groups never wait for the network; stale server responses are dropped.

## Dependencies

### Requires
- 002-song-index
- 005-server-search (backend)

### Enables
- None

## Edge Cases

| Scenario | Expected Behavior |
|----------|-------------------|
| Server error | Same as offline note, with Retry |

## Out of Scope

- Search history sync
