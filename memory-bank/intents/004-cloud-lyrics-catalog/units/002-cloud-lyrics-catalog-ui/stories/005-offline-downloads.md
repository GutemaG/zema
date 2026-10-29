---
id: 005-offline-downloads
unit: 002-cloud-lyrics-catalog-ui
intent: 004-cloud-lyrics-catalog
status: complete
priority: should
created: '2026-10-29T05:59:04Z'
assigned_bolt: 026-cloud-lyrics-catalog-ui
implemented: true
---

# Story: 005-offline-downloads

## User Story

**As a** listener
**I want** to download all lyrics before going offline
**So that** I have every song when travelling

## Acceptance Criteria

- [x] **Given** Settings → Lyrics, **When** shown, **Then** storage used by downloaded lyrics shows
- [x] **Given** "Download all lyrics for offline", **When** started, **Then** every approved song is cached with progress and can be cancelled
- [x] **Given** "Clear downloaded lyrics", **When** confirmed, **Then** cached lyrics are removed but links and the index stay

## Technical Notes

- Downloads in small batches; a failure stops with a message and keeps what finished.

## Dependencies

### Requires
- 003-lyrics-cache

### Enables
- None

## Edge Cases

| Scenario | Expected Behavior |
|----------|-------------------|
| Leaving Settings mid-download | Download continues; progress shows on return |

## Out of Scope

- Background download service
