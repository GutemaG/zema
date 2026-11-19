---
id: 002-contribution-review
unit: 002-admin-website
intent: 008-admin-website
status: complete
priority: must
created: '2026-11-19T10:00:00Z'
assigned_bolt: 056-admin-website
implemented: true
---

# Story: 002-contribution-review

Contribution review

**As a** moderator
**I want** to review contributions side by side
**So that** I approve only good lyrics

## Acceptance Criteria

- [x] **Given** the queue, **When** it loads, **Then** pending contributions show kind, song, author and age, filterable by kind
- [x] **Given** one is opened, **When** it is an edit, **Then** the current and submitted lines show side by side with changes marked; a new song shows its lines; timings show as a list of line times
- [x] **Given** Approve, Request changes or Reject, **When** pressed, **Then** `review_contribution` runs (note required for the last two) and the item leaves the queue
- [x] **Given** `already_reviewed` or a network error, **When** it happens, **Then** a message shows and the queue reloads
