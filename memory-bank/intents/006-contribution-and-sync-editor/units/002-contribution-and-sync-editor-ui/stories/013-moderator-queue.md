---
id: 013-moderator-queue
unit: 002-contribution-and-sync-editor-ui
intent: 006-contribution-and-sync-editor
status: complete
priority: must
created: '2026-11-02T07:00:52Z'
assigned_bolt: 051-contribution-and-sync-editor-ui
implemented: true
---

# Story: 013-moderator-queue

## User Story

**As a** moderator
**I want** to review contributions in the app
**So that** good content gets published quickly

## Acceptance Criteria

- [x] **Given** a moderator, **When** S05 or Profile, **Then** Review queue shows pending items oldest first with a count and type filter; the role badge reads Moderator
- [x] **Given** an item, **When** opened, **Then** a new song shows its lyrics; a correction a line diff and timings to be removed, flagged if based on an older version; a recording its source (YouTube opens the app); sync a silent highlighting preview; and a checklist
- [x] **Given** Approve / Request changes / Reject, **When** pressed, **Then** comment or reason is required for the last two; the item leaves the queue
- [x] **Given** an item reviewed by someone else, **When** acted on, **Then** Already reviewed shows and the queue refreshes
- [ ] **Given** the emulator, the intent check, **When** user A submits lyrics + sync for a local song, a moderator approves, a wiped install with the same file opens it, **Then** the synced lyrics show

## Technical Notes

- Non-moderators never see the entry. Own contributions are hidden from one's queue.

## Dependencies

### Requires
- 011-corrections
- 012-my-contributions-and-badge
- 002-review-and-moderator-role (backend)

### Enables
- None

## Edge Cases

| Scenario | Expected Behavior |
|----------|-------------------|
| Empty queue | Empty state |

## Out of Scope

- Admin website (008)
