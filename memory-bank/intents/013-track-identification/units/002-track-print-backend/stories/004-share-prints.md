---
id: 004-share-prints
unit: 002-track-print-backend
intent: 013-track-identification
status: planned
priority: must
created: '2026-11-19T16:00:00Z'
assigned_bolt: 060-track-print-backend
implemented: false
---

# Story: 004-share-prints

Share prints

**As a** listener who agreed to share
**I want** my linked files to help others
**So that** their untagged copies get found

## Acceptance Criteria

- [ ] **Given** `share_track_print(song, version, print, duration, install_id)`, **When** the print is valid (`track_print_error`: length, duration within 3 s or 5 % of a recording when known), **Then** it is pending
- [ ] **Given** a pending print, **When** another install sends one for the same song that matches it, **Then** both publish
- [ ] **Given** a print matching a published print of a **different** song, **When** shared, **Then** it stays pending for a moderator
- [ ] **Given** an install, **When** it shares more than 30 in a day, **Then** it is refused
- [ ] **Given** a moderator, **When** they call `moderator_track_prints` / `review_track_print(id, approve)`, **Then** pending prints list and publish or drop
- [ ] **Given** pgTAP, **When** run, **Then** sharing, agreement, conflicts, limits and roles are tested
