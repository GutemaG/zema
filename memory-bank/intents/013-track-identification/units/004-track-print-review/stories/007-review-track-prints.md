---
id: 007-review-track-prints
unit: 004-track-print-review
intent: 013-track-identification
status: planned
priority: should
created: '2026-11-19T16:00:00Z'
assigned_bolt: 062-track-print-review
implemented: false
---

# Story: 007-review-track-prints

Review shared prints

**As a** moderator
**I want** to see pending track prints
**So that** conflicts and single shares get decided

## Acceptance Criteria

- [ ] **Given** pending prints, **When** the Fingerprints page opens, **Then** they list with song, installs, length and whether they conflict with another song
- [ ] **Given** one, **When** approved or rejected, **Then** `review_track_print` is called and it leaves the list
