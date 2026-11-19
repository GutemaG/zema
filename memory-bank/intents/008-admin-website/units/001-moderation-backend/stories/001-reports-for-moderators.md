---
id: 001-reports-for-moderators
unit: 001-moderation-backend
intent: 008-admin-website
status: complete
priority: must
created: '2026-11-19T10:00:00Z'
assigned_bolt: 054-moderation-backend
implemented: true
---

# Story: 001-reports-for-moderators

Reports for moderators

**As a** moderator
**I want** to see open reports and close them
**So that** wrong lyrics get fixed

## Acceptance Criteria

- [x] **Given** a moderator, **When** they call `moderator_reports(status default 'open')`, **Then** reports come back newest first with song id, song title, recording id, reason, note and time (never the install hash)
- [x] **Given** a moderator, **When** they call `resolve_report(id, status)` with resolved or dismissed, **Then** the status changes; `open` or an unknown id is refused
- [x] **Given** a user without the role, **When** they call either, **Then** `not_moderator`
- [x] **Given** pgTAP, **When** run, **Then** roles, ordering, the hidden hash and bad input are tested
