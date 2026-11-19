---
id: 004-reports-page
unit: 002-admin-website
intent: 008-admin-website
status: complete
priority: must
created: '2026-11-19T10:00:00Z'
assigned_bolt: 057-admin-website
implemented: true
---

# Story: 004-reports-page

Reports page

**As a** moderator
**I want** to work through reports
**So that** I fix what listeners flag

## Acceptance Criteria

- [x] **Given** open reports, **When** the page loads, **Then** they list with song, reason, note and age; a filter shows resolved and dismissed
- [x] **Given** a report, **When** Resolve or Dismiss is pressed, **Then** `resolve_report` runs and it leaves the open list; the song opens in the catalog page
