---
id: 009-review-and-submit
unit: 002-contribution-and-sync-editor-ui
intent: 006-contribution-and-sync-editor
status: complete
priority: must
created: '2026-11-02T07:00:52Z'
assigned_bolt: 048-contribution-and-sync-editor-ui
implemented: true
---

# Story: 009-review-and-submit

## User Story

**As a** contributor
**I want** to check my contribution and submit it
**So that** it goes to the moderators and I see it right away

## Acceptance Criteria

- [ ] **Given** S22, **When** shown, **Then** song details, lyrics in play order, the recording and the sync status (Synced / Text only / YouTube — not synced), each with Edit
- [ ] **Given** Submit, **When** pressed, **Then** the rules run again and one contribution is sent; success shows a message with a link to My contributions
- [ ] **Given** offline or a server error, **When** Submit, **Then** the draft is kept, a message names the problem, and Submit can be retried
- [ ] **Given** a pending contribution linked to a local track, **When** the track plays, **Then** its lyrics and timings show on this phone marked Pending review
- [ ] **Given** approval / rejection, **When** seen, **Then** the catalog version replaces the copy / the copy is removed and the track goes back to what it had

## Technical Notes

- Own copy stored in Drift with the contribution ID; other phones never see it.

## Dependencies

### Requires
- 008-sync-editor-focus-and-preview
- 002-contribution-repository
- 003-publish-on-approval (backend)

### Enables
- 010-duplicate-check-and-entry-points
- 012-my-contributions-and-badge

## Edge Cases

| Scenario | Expected Behavior |
|----------|-------------------|
| Limit reached | Message names the limit; draft kept |

## Out of Scope

- Notifications (012)
