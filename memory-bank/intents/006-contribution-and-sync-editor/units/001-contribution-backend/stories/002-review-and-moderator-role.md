---
id: 002-review-and-moderator-role
unit: 001-contribution-backend
intent: 006-contribution-and-sync-editor
status: planned
priority: must
created: '2026-11-02T07:00:52Z'
assigned_bolt: 040-contribution-backend
implemented: false
---

# Story: 002-review-and-moderator-role

## User Story

**As a** moderator
**I want** to approve, request changes or reject pending contributions
**So that** only good content becomes public

## Acceptance Criteria

- [ ] **Given** a moderator, **When** they read the queue (`moderator_queue(kind?)`), **Then** pending contributions of all users come back oldest first with author display name, kind, payload and the current song document for edits
- [ ] **Given** a moderator and a pending contribution by someone else, **When** they call `review_contribution(id, decision, note)`, **Then** the status, `review_note`, `reviewer_id` and `reviewed_at` are set
- [ ] **Given** Request changes or Reject, **When** the note is empty, **Then** it is refused
- [ ] **Given** a contributor without the role, or the moderator's own contribution, **When** they review, **Then** it is refused
- [ ] **Given** two reviews of the same contribution, **When** the second runs, **Then** it fails with `already_reviewed` and nothing changes
- [ ] **Given** the owner, **When** they run `backend/scripts/moderator.sh grant|revoke <email>` against the local (or later hosted) database, **Then** the `moderator` role is added or removed; an unknown email is reported; the service key is read from the environment and never written to a file
- [ ] **Given** pgTAP, **When** run, **Then** role checks, no self-review, required notes and races are tested

## Technical Notes

- Lock the row (`for update`) so racing reviews serialize. `admin` counts as a moderator. Document the script in `docs/moderators.md`.

## Dependencies

### Requires
- 001-submit-contributions

### Enables
- 003-publish-on-approval
- 013-moderator-queue (ui)

## Edge Cases

| Scenario | Expected Behavior |
|----------|-------------------|
| Moderator reviews after the role is revoked | Refused |
| Approve with a note | Allowed; the note is shown to the author |

## Out of Scope

- Role management screens (008)
