---
stage: plan
bolt: 040-contribution-backend
created: 2026-11-02T08:35:00Z
---

## Implementation Plan: contribution-backend (bolt 2 of 3)

### Objective

Moderators read the queue of pending contributions and review them: approve, request
changes or reject. The owner grants and removes the moderator role with a script.
Story: `002-review-and-moderator-role`.

The owner asked for bolts 040 and 041 together, following my recommendations without
checkpoints. They can't run truly in parallel: publishing runs inside the review
function, and both reset the same local database. So 040 calls a
`publish_contribution` that does nothing yet, and 041 replaces it.

### Deliverables

- **`migrations/20261102010000_review_contributions.sql`**:
  - `is_moderator(user_id)`: true for the `moderator` or `admin` role.
  - **`moderator_queue(kind default null)`**, for moderators only:
    - It returns pending contributions by other users, oldest `submitted_at` first.
    - Each row has: ID, kind, song ID, base version, the song's current version,
      payload, revision, author display name, the previous review note, and the
      current song document (for diffs).
  - **`review_contribution(id, decision, note default null)`**:
    - `decision` is `approved`, `changes_requested` or `rejected`.
    - It sets the status, the note, the reviewer and the time.
    - On approval it calls `publish_contribution` first, then returns the song ID.
  - `publish_contribution(contribution)`: a placeholder that returns the song ID; 041
    replaces it.
  - **`set_moderator(email, enabled)`**:
    - Only `service_role` and the owner can run it, not the app.
    - It adds or removes the `moderator` role.
    - It returns `granted`, `revoked` or `unchanged`, and raises `unknown_email`.
- **`backend/scripts/moderator.sh grant|revoke <email>`**:
  - It calls `set_moderator` through `psql`, using `DATABASE_URL`.
  - The default is the local database's standard URL. A hosted URL comes from the
    environment and is never written to a file.
- **`docs/moderators.md`**: how to grant and revoke, and what a moderator can do.
- **`tests/database/014_review.test.sql`**: pgTAP tests.

### Error codes (added to the shared list)

- `not_signed_in` (`28000`), `not_moderator` (`42501`)
- `own_contribution` (`42501`)
- `already_reviewed` (`PT409`, which PostgREST turns into HTTP 409)
- `unknown_contribution`, `bad_decision`, `note_required`, `note_too_long` (over 1,000
  characters) (all `22023`)

### Technical Approach

- **Review locks the row (`for update`).** A second moderator waits for the first,
  then finds it isn't pending and gets `already_reviewed`.
- **The note is trimmed.** It's required for `changes_requested` and `rejected`, and
  optional on approval.
- **The queue hides the moderator's own contributions**, as story ui 013 asks.
- **The script:**
  - It uses `psql -v` variables, so the email is never put into the SQL text.
  - It checks the action and the email's shape before connecting.

### Acceptance Criteria

- [ ] A moderator gets the queue of other users' pending contributions, oldest first,
  filtered by kind, with the author's name and the current song document.
- [ ] Review sets the status, note, reviewer and time. A note is required for request
  changes and reject.
- [ ] A contributor, a guest, or the author of the contribution is refused.
- [ ] A second review is refused with `already_reviewed`, and nothing changes.
- [ ] `set_moderator` grants, revokes and reports an unknown email. The app's roles
  can't call it.
- [ ] `moderator.sh` grants and revokes against the local database.
- [ ] The whole pgTAP suite passes.
