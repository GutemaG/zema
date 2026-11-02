---
stage: test
bolt: 040-contribution-backend
created: 2026-11-02T09:40:00Z
---

## Test Report: contribution-backend (bolt 2 of 3)

### Summary

- **Tests**: 545 pgTAP tests in 15 files, all passing. 42 are new, in
  `014_review.test.sql`.
- **Planted bugs**: 14 for this bolt. 13 were caught on the first run; the 14th was
  caught after a test was added (see Issues Found).
- **The moderator script** was run against the local database.

### Test Files

- [x] `backend/supabase/tests/database/014_review.test.sql` (42):
  - **Who reads the queue**: a contributor gets `not_moderator`, no user gets
    `not_signed_in`, and `anon` can't call it.
  - **The queue**:
    - Other users' pending contributions, oldest first. Approved ones and the
      moderator's own are left out.
    - The kind filter works.
    - Each row has the author's name, the song ID, the current version, the current
      document and the revision. A new song has no current song.
    - An admin reads it too.
  - **Refused reviews**:
    - A note is required for request changes, and a blank one doesn't count. A reason
      is required for reject.
    - 1,001 characters is too long; 1,000 is fine.
    - `pending` isn't a decision. An unknown ID is refused.
    - A moderator can't review their own contribution. A contributor and `anon` are
      refused.
  - **Reviews**:
    - Request changes sets the status, trimmed note, reviewer and time.
    - A second review is refused with `already_reviewed`, after a rejection too and
      for one approved before, and changes nothing.
    - Approval with no note returns the published song and points the contribution at
      it.
    - The author reads the decision and note.
  - **A former moderator** can't read the queue or review.
  - **Granting**:
    - The app can't grant, and the app's roles have no execute right on it at all.
    - The owner grants, matches the email without case or spaces, and revokes; other
      roles stay; revoking again changes nothing; an unknown email is refused.
    - Admins count as moderators.
    - `service_role` may run it. The app can't call `publish_contribution` directly.

### Acceptance Criteria Validation

- ✅ **Queue of other users' pending contributions, oldest first, filtered, with the
  author and the current song**: the queue tests.
- ✅ **Review sets status, note, reviewer and time; a note is required**: the review
  and refused-review tests.
- ✅ **Contributor, guest and author refused**: the who-reads and refused-review tests.
- ✅ **A second review refused, nothing changed**: the `already_reviewed` tests.
- ✅ **`set_moderator` grants, revokes and reports an unknown email; not callable by
  the app**: the granting tests.
- ✅ **`moderator.sh` grants and revokes locally**: run by hand.
  - It covered grant, unchanged, revoke, an unknown email (exit 3), a malformed email
    and a wrong action (exit 2).
- ✅ **The whole pgTAP suite passes**: 545 of 545.

### Planted Bugs (14)

- **Caught**:
  - own review allowed
  - second review allowed
  - note optional
  - the queue shows the moderator's own, or reviewed ones, or newest first
  - admin not counted as a moderator (a test file aborted)
  - anyone can moderate
  - approval skips publishing
  - note not trimmed
  - revoke drops all roles
  - reviewer not stored
  - song ID not stored
- **Missed first, then caught**: **the app can grant.**
  - Calling `set_moderator` failed anyway, because the app can't write `user_roles`.
    So the "the app cannot grant" test passed for the wrong reason.
  - A direct check that `authenticated` and `anon` have no execute right now catches
    it.

### Issues Found

- **The queue's parameter couldn't be named `kind`**, because that's also an output
  column. Renamed to `only_kind`.
- **The test for "the app can't grant" relied on the table's write grants.** A direct
  privilege check was added.

### Not Checked / Follow-ups

- **Two moderators reviewing at the same moment** can't be tested in one pgTAP session.
  The row lock gives the second `already_reviewed`; this was reviewed, not tested.
- **HTTP 409 for `already_reviewed` through PostgREST** is checked in bolt 042's
  `zema_data` integration tests.
