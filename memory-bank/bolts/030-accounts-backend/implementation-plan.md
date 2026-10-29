---
stage: plan
bolt: 030-accounts-backend
created: 2026-10-29T19:28:00Z
---

## Implementation Plan: accounts-backend (bolt 2 of 2)

### Objective

- **Story 003, backups table**: each signed-in user has at most one private backup on
  the server. It is a JSON document with a format version, limited to 2 MB, and only
  that user can read or replace it.
- **Story 004, `delete_account`**: a signed-in user can delete their own account. That
  removes the auth user, the profile, the roles, the backup, and the user's sessions.

### Deliverables

#### Migration `20261029070000_backups.sql`

- **`public.backups`**
  - `user_id uuid primary key references auth.users on delete cascade`
  - `format int not null check (format >= 1)`
  - `document jsonb not null`, which must be a JSON object
  - `size_bytes int`, generated from `octet_length(document::text)`, with a check of
    `<= 2097152` (2 MB)
  - `device text`, at most 100 characters: the phone's name, for "Backup from Pixel 7"
  - `updated_at timestamptz not null`, always set by the server
  - RLS on
- **Reading**: a `select` policy for `authenticated` where `user_id = auth.uid()`.
  - The app reads the summary columns (`format`, `size_bytes`, `device`,
    `updated_at`) without the document, for S26 and S25b.
  - It reads the document when restoring.
- **Writing goes through `save_backup(document jsonb, format int, device text)`**,
  which returns `updated_at`. Like `submit_report`, the table itself stays closed to
  writes.
  - It is `security definer` with an empty `search_path`, and uses `auth.uid()`, so a
    user can't write another user's row.
  - **It refuses**:
    - no user: `28000`, "Not signed in"
    - a document that isn't an object, or a format below 1: `22023`
    - over 2 MB: `54000`, "Backup too large", a code the app can recognise
    - a device name over 100 characters: `22023`
  - **Upsert**: `insert … on conflict (user_id) do update`, with `updated_at = now()`.
    Only the latest backup is kept, and the last write wins.
  - Execute is revoked from `public` and `anon`, and granted to `authenticated` only.
- **Policies**: no insert, update or delete policies, and the writes stay revoked
  (bolt 019's defaults).

#### Migration `20261029070100_delete_account.sql`

- **`delete_account()`**, which returns nothing:
  - `security definer`, with an empty `search_path`.
  - Raises `28000` when there is no `auth.uid()`.
  - Runs `delete from auth.users where id = auth.uid()`. The cascades remove the
    profile, the roles, the backup, the sessions, the refresh tokens and the
    identities. Contributions keep their row, with `author_id` set to null.
  - Reports are anonymous (an install hash) and stay.
  - A second call finds no user and does nothing, without failing.
- Execute is granted to `authenticated` only.

#### pgTAP `011_backups.test.sql`

- **Saving**: a user saves a backup. The row has the format, the device, the
  generated size and a server time.
- **Replacing**: a second save replaces it. There is one row, with the new document
  and a later `updated_at`.
- **Reading**:
  - A user reads only their own backup.
  - Another user sees none.
  - `anon` sees none.
- **Refused**:
  - a document just over 2 MB (`54000`), while one just under is accepted
  - a non-object document, format 0, and a device name of 101 characters (`22023`)
  - `anon` calling `save_backup` (`42501`)
  - direct `insert`, `update` and `delete` on `backups` by a user (`42501`)
- **No user**: an `authenticated` call without a `sub` claim is refused (`28000`).
- **Other users**: saving as user B doesn't touch user A's backup.

#### pgTAP `012_delete_account.test.sql`

- **What goes**: `delete_account()` as user A removes A's auth user, profile, roles,
  backup and sessions.
- **What stays**: user B's rows, and A's reports.
- **A second call** succeeds and does nothing.
- **Refused**: `anon` calling it (`42501`), and `authenticated` with no `sub` (`28000`).
- **Not affected**: a contribution by A is kept, with `author_id` null.

#### Guards

- **`001`**: the table list gains `backups`. The only write policy is still `profiles`
  UPDATE.

### Dependencies

- **Bolt 029**: `profiles`, `user_roles`, the sign-up trigger, and the test-user
  pattern.
- **The auth schema's cascades** on `sessions`, `refresh_tokens` and `identities`.
  These were checked: all are `on delete cascade`.

### Technical Approach

- **Writes go through checked functions**, which is the backend's existing rule. A
  REST upsert would need update rights on `user_id`, and would let the client choose
  `updated_at`.
- **The size check lives in two places**: the function checks first, so the app gets
  the clear `54000`, and the table constraint stays as the guard.

### End-to-End Check (local backend, Test stage)

Through the real API, with the anon key never printed:

1. Sign up a user.
2. `save_backup` twice, then read the summary and the document.
3. Try another user's row.
4. Call `delete_account`.
5. Refreshing the session must fail, and the user's rows must be gone.

### Acceptance Criteria

- [ ] One backup per user, replaced on save, with the server's time
- [ ] Own backup only. `anon` and other users see nothing
- [ ] More than 2 MB is refused with a recognisable code. Bad input is refused
- [ ] No direct table writes. Saving works only for signed-in users
- [ ] `delete_account` removes the auth user, the profile, the roles, the backup and
      the sessions, and keeps other users' rows and anonymous reports
- [ ] `anon` can't call either function
- [ ] `supabase db reset` and `supabase test db` pass. The e2e check passes. The key
      scan is clean
