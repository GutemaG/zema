---
stage: implement
bolt: 040-contribution-backend
created: 2026-11-02T09:10:00Z
---

## Implementation Walkthrough: contribution-backend (bolt 2 of 3)

### Summary

Moderators can now read the queue of other users' pending contributions and review
them: approve, request changes or reject. Approving publishes the contribution in the
same transaction; bolt 041 supplies the publishing. The owner grants and removes the
moderator role with a script that only the server side can run.

### Structure Overview

- **One guard**, `require_moderator`, for both API functions. It refuses guests and
  non-moderators.
- **The queue** is a read-only function that joins each contribution with its author's
  profile and the song's current document.
- **The review function** locks the contribution, checks the decision and note, and
  publishes on approval. Then it records the decision and the song ID.
- **Role changes** go through `set_moderator`, which only `service_role` and the owner
  can run. The shell script calls it.

### Completed Work

- [x] `backend/supabase/migrations/20261102010000_review_contributions.sql`:
  `is_moderator`, `require_moderator`, `moderator_queue`, `review_contribution`, a
  placeholder `publish_contribution` (replaced by 041), and `set_moderator`.
- [x] `backend/scripts/moderator.sh`: grant or revoke by email. It runs against the
  local database container, or against `DATABASE_URL` with `psql`.
- [x] `docs/moderators.md`: how to grant and revoke, and what moderators can do.

### Key Decisions

- **`already_reviewed` uses errcode `PT409`**, so the app gets HTTP 409 and can
  refresh the queue.
- **The queue's filter parameter is `only_kind`.** It can't be `kind`, because that's
  also an output column.
- **The script runs `psql` inside the database container** when no `DATABASE_URL` is
  set, because `psql` isn't installed on the development machine.
  - The email goes in as a `psql` variable, never pasted into the SQL.
  - The script checks the email's shape and the action before connecting.
- **A review returns the song ID**, and approval stores it on the contribution. That
  way a new song's contribution points at the song it became.

### Deviations from Plan

None.

### Dependencies Added

None.

### Developer Notes

- Tried against the local database: grant, case-insensitive match (unchanged), revoke,
  an unknown email (exit 3), a malformed email and a wrong action (exit 2). The test
  user was removed afterwards.
- Two moderators racing: the second waits on the row lock, then gets
  `already_reviewed`. pgTAP runs in one session, so the tests check the sequential
  case.
