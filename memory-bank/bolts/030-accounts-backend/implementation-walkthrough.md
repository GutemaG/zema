---
stage: implement
bolt: 030-accounts-backend
created: 2026-10-29T19:29:48Z
---

## Implementation Walkthrough: accounts-backend (bolt 2 of 2)

### Summary

- Each signed-in user can keep one private backup on the server: a JSON document of at
  most 2 MB.
- The backup is saved only through `save_backup`, which always writes the caller's
  own row, with the server's time.
- `delete_account` removes the caller's auth user. The database's cascades then
  remove their profile, roles, backup and sessions.

### Structure Overview

- **Two migrations**: the backups table with its save function, and the delete
  function.
- **The same pattern as reports in 004**: the table is readable through one policy,
  and writes go only through checked `security definer` functions. Those functions
  have an empty `search_path`, and only `authenticated` can call them.

### Completed Work

- [x] `backend/supabase/migrations/20261029070000_backups.sql`
  - **`backups`**: one row per user.
    - The format must be 1 or higher, and the document must be a JSON object.
    - A generated size column, checked against 2 MB.
    - A device name of at most 100 characters, and a time set by the server.
    - It is deleted with the user.
  - **`save_backup(document, format, device)`**
    - **Refuses**:
      - no user: `28000`
      - a non-object or missing document: `22023`
      - a format below 1: `22023`
      - a long device name: `22023`
      - over 2 MB: `54000`, "Backup too large"
    - **Then** it inserts or replaces the caller's row, trims the device name, and
      returns the saved time.
  - **Policy**: users read their own backup.
- [x] `backend/supabase/migrations/20261029070100_delete_account.sql`
  - **`delete_account()`**: refuses a call with no user (`28000`), and otherwise
    deletes the caller from `auth.users`.
  - **A repeat call** does nothing.
- [x] `backend/supabase/tests/database/011_backups.test.sql` (26) and
  `012_delete_account.test.sql` (15): written now to check the migrations. They are
  described in the test stage.
- [x] `backend/supabase/tests/database/001_catalog_schema.test.sql`: the table list
  includes `backups`.
- [x] `backend/supabase/tests/database/002_read_policies.test.sql`: the catalog
  read-policy count leaves out `backups`, as it does profiles and roles.
- [x] `backend/README.md`: backups, `save_backup` and `delete_account` in the
  accounts section.

### Key Decisions

- **Saving through a function, not a REST upsert.** An upsert would need update rights
  on `user_id`, and would let the client choose `updated_at`. The function takes
  both from the server.
- **Two size checks.** The function checks first, so the app gets a clear `54000`.
  The table's check stays as the guard.
- **One delete removes everything.** Deleting from `auth.users` is enough, because
  `sessions`, `refresh_tokens`, `identities`, `profiles`, `user_roles` and
  `backups` all cascade, and `contributions.author_id` is set to null.

### Deviations from Plan

- **One extra guard.** `002` also needed `backups` left out of its catalog
  read-policy count. The plan only named `001`.

### Dependencies Added

- None.

### Developer Notes

- **The size is the JSON text's length.** `size_bytes` measures Postgres's own text
  form of the `jsonb` (`{"x": "…"}`, with spaces), not the bytes the app sent.
  Compact JSON from the app can come out slightly smaller or larger, so the app
  should keep well under 2 MB. The target is under 1 MB.
- **`db reset` was run again.** The local database holds only the seed.
