---
id: 006-share-after-link
unit: 003-track-print-app
intent: 013-track-identification
status: complete
priority: should
created: '2026-11-19T16:00:00Z'
assigned_bolt: 061-track-print-app
implemented: true
---

# Story: 006-share-after-link

Share after a link

**As a** listener who agreed to share
**I want** files that link by title or by hand to send their print
**So that** the catalog grows

## Acceptance Criteria

- [x] **Given** consent (the existing Share switch, shown again) and a track linked by title or by hand, **When** printed, **Then** its print is shared once per song and version
- [x] (via the sharer once approved and linked) **Given** a contribution with a file recording, **When** sent, **Then** its print goes with it
- [x] **Given** no consent, **When** linked, **Then** nothing is sent
