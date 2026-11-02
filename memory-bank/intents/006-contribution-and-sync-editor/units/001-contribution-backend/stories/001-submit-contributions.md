---
id: 001-submit-contributions
unit: 001-contribution-backend
intent: 006-contribution-and-sync-editor
status: planned
priority: must
created: '2026-11-02T07:00:52Z'
assigned_bolt: 039-contribution-backend
implemented: false
---

# Story: 001-submit-contributions

## User Story

**As a** signed-in contributor
**I want** to send my lyrics, recording or timings for review
**So that** moderators can approve them

## Acceptance Criteria

- [ ] **Given** a signed-in user and a valid payload, **When** they call `submit_contribution(kind, song_id, base_version, payload)`, **Then** a `pending` row is made with them as author and its ID is returned
- [ ] **Given** a payload breaking the shared rules (no title, no section, empty play order, unknown block, timings not strictly increasing or past the duration, bad video ID), **When** submitted, **Then** it is refused with a named error code
- [ ] **Given** a user with 20 pending contributions, or 30 submitted today, or a payload over 256 KB, **When** they submit, **Then** it is refused with a limit error
- [ ] **Given** the author and a `changes_requested` contribution, **When** they call `resubmit_contribution(id, payload)`, **Then** the payload is replaced, the status goes back to `pending` and the review note stays readable in history; any other status or user is refused
- [ ] **Given** signed-in users and `anon`, **When** they read `contributions`, **Then** users see only their own rows; `anon` sees none; nobody can insert, update or delete directly
- [ ] **Given** the new `recording` kind, **When** a recording is submitted for an existing approved song, **Then** it is accepted; `edit_lyrics`, `recording` and `sync_timing` need an existing approved `song_id`, `new_song` must not have one
- [ ] **Given** pgTAP, **When** run, **Then** rules, limits, RLS and resubmit are tested

## Technical Notes

- Rules match `zema_core` validation (ui 001); keep error codes shared in one place. Count limits by `author_id`, today in UTC. `security definer` RPCs with `search_path = ''`, as in 004/005.

## Dependencies

### Requires
- None

### Enables
- 002-review-and-moderator-role
- 002-contribution-repository (ui)

## Edge Cases

| Scenario | Expected Behavior |
|----------|-------------------|
| Guest calls submit | Refused: not signed in |
| Same payload sent twice quickly | Two rows; both count towards the limits |
| Song deleted after submit | `song_id` set null; the moderator sees it |

## Out of Scope

- Reviewing and publishing (002, 003)
