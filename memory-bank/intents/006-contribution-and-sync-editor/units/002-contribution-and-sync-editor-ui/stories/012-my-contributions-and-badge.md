---
id: 012-my-contributions-and-badge
unit: 002-contribution-and-sync-editor-ui
intent: 006-contribution-and-sync-editor
status: complete
priority: must
created: '2026-11-02T07:00:52Z'
assigned_bolt: 050-contribution-and-sync-editor-ui
implemented: true
---

# Story: 012-my-contributions-and-badge

## User Story

**As a** contributor
**I want** to see my submissions and hear when their status changes
**So that** I know what happened and can fix what needs changes

## Acceptance Criteria

- [x] **Given** S23 (from S05 and Profile), **When** opened, **Then** tabs Pending / Approved / Needs changes / Rejected list cards with song, type, date and comment or reason
- [x] **Given** a Needs changes card, **When** Edit, **Then** the flow reopens with the submitted data; Submit resubmits the same contribution
- [x] **Given** the app opens or resumes, signed in and online, **When** statuses changed since the last check, **Then** a badge shows on Profile and S05's link, and one message per change; opening S23 clears the badge
- [x] **Given** Profile, **When** shown, **Then** stats lyrics added, synced, approved

## Technical Notes

- Last check time per user in prefs, like 005's backup status.

## Dependencies

### Requires
- 009-review-and-submit

### Enables
- 013-moderator-queue

## Edge Cases

| Scenario | Expected Behavior |
|----------|-------------------|
| Offline on resume | No check, no badge change |

## Out of Scope

- Push notifications
