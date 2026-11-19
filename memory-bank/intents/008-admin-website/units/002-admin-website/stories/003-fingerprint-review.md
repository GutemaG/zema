---
id: 003-fingerprint-review
unit: 002-admin-website
intent: 008-admin-website
status: complete
priority: should
created: '2026-11-19T10:00:00Z'
assigned_bolt: 056-admin-website
implemented: true
---

# Story: 003-fingerprint-review

Fingerprint review

**As a** moderator
**I want** to approve shared fingerprints
**So that** songs can be identified by sound

## Acceptance Criteria

- [x] **Given** pending fingerprints, **When** the page loads, **Then** each shows its recording, song and length; Approve or Reject calls `review_fingerprint`
- [x] **Given** none (uploads paused), **When** the page loads, **Then** it says so
