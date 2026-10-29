---
stage: test
bolt: 030-accounts-backend
created: 2026-10-29T19:32:59Z
---

## Test Report: accounts-backend (bolt 2 of 2)

### Summary

- **Tests**: 373/373 pass in `supabase test db`, of which 42 are new:
  - `011_backups`: 27
  - `012_delete_account`: 15
  - `001` and `002`: guards updated
- **Rebuild**: `supabase db reset` rebuilds the database cleanly.
- **Coverage**: pgTAP has no coverage tool. Planted bugs were used instead, and caught
  16 of 16 after one test was added.
- **No app code changed**, so the app's tests weren't rerun.

### Test Files

- [x] `backend/supabase/tests/database/011_backups.test.sql` (27)
  - **Saving**:
    - The row holds the format, the document, the trimmed device name and the size.
    - The time is set by the server.
  - **Saving again**:
    - It replaces the backup: one row, with the new document, format and device.
    - The replaced backup gets the new time.
    - `save_backup` returns that time.
  - **Size and input**:
    - Exactly 2 MB is accepted, and its size is recorded.
    - One byte over is refused (`54000`).
    - A non-object or missing document, format 0, and a device name over 100
      characters are refused (`22023`).
  - **Direct writes**: `insert`, `update` and `delete` on the table are refused
    (`42501`).
  - **Other users**:
    - User B sees no backup, saves their own, and reads only that.
    - A's backup is untouched.
  - **Callers who aren't signed in**:
    - A token with no user is refused (`28000`).
    - `anon` can't save (`42501`) or read.
  - **Also checked**:
    - a fixed `search_path`
    - deleting a user removes their backup
    - the table has exactly one policy
- [x] `backend/supabase/tests/database/012_delete_account.test.sql` (15)
  - **What goes**:
    - Deleting works, and a second call does nothing.
    - The auth user, profile, roles, backup and sessions are all removed.
  - **What stays**:
    - Contributions, with no author.
    - Anonymous reports.
    - All of another user's rows.
  - **Refused**: a token with no user (`28000`) and `anon` (`42501`).
  - **Privileges**: `authenticated` only, and a fixed `search_path`.
- [x] `001_catalog_schema` and `002_read_policies`: `backups` is in the table
  list, and left out of the catalog read-policy count.

### End-to-End Check (real auth server and API, local backend)

Two users were signed up through `/auth/v1/signup`. The anon key was never printed.

- **A saves twice**: two server times. The summary shows format 1, 21 bytes and
  "Pixel 7" with the second time, and the document is the second one.
- **B**: saves, reads only its own backup, and gets `42501` patching A's backup.
- **Refused**:
  - a 2.1 MB backup: `54000 Backup too large`
  - `anon` saving or deleting: `42501`
- **A deletes the account**: HTTP 204.
  - A's refresh token is refused (`refresh_token_not_found`).
  - `/auth/v1/user` with A's token is refused (`user_not_found`).
  - 0 of A's rows are left. B's rows were intact, and B was then removed.

### Planted Bugs (16; each planted on the local database, tested, then undone)

- **Caught on the first run (15)**:
  - backups readable by all
  - no size check in the function
  - no size check in the function or the table
  - the size limit off by one
  - a non-object accepted
  - no sign-in check in save
  - insert instead of replace
  - `anon` can save
  - the table writable
  - delete does nothing
  - delete removes everyone
  - delete removes only the profile
  - no sign-in check in delete
  - `anon` can delete
  - the backup kept after the user is deleted
- **Missed at first: a replace keeping the old time**
  - `now()` doesn't change inside a transaction, so the first save and the replace
    had the same time.
  - The test now back-dates the first save, and checks that the replace sets the new
    time. That bug is now caught.
- **After restoring**: 373/373 pass.

### Acceptance Criteria Validation

- ✅ **One backup per user, replaced on save, with the server's time**: pgTAP and e2e.
- ✅ **Only your own backup. `anon` and other users see nothing**: pgTAP and e2e.
- ✅ **Over 2 MB refused with `54000`, and bad input refused**: pgTAP and e2e.
- ✅ **No direct table writes. Saving works only for signed-in users**: pgTAP and e2e.
- ✅ **`delete_account` removes the auth user, profile, roles, backup and sessions,
  and keeps others' rows and the reports**: pgTAP and e2e.
- ✅ **`anon` can't call either function**: pgTAP and e2e.
- ✅ **`db reset` and `test db` pass, and the e2e check passes**. The key scan runs
  before the commit.

### Issues Found

- The missed "keeps the old time" bug above. The test is fixed.

### Notes

- **A deleted user's access token** is a stateless JWT, so PostgREST still accepts it
  until it expires, about an hour. But no rows match it, and a save fails on the
  missing user. The app signs out locally right after deleting the account (bolt 033).
- **The backend unit is complete.** Next is bolt 031, the app's auth repository.
