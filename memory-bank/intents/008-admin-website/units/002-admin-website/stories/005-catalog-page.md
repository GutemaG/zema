---
id: 005-catalog-page
unit: 002-admin-website
intent: 008-admin-website
status: complete
priority: must
created: '2026-11-19T10:00:00Z'
assigned_bolt: 057-admin-website
implemented: true
---

# Story: 005-catalog-page

Catalog page

**As a** moderator
**I want** to find songs and hide or restore them
**So that** bad songs leave the app quickly

## Acceptance Criteria

- [x] **Given** a search, **When** typed, **Then** matching songs list with status, paged
- [x] **Given** a song, **When** opened, **Then** its lyrics show; Hide asks to confirm and calls `set_song_hidden`; a hidden song shows Restore
