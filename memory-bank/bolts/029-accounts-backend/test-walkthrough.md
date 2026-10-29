---
stage: test
bolt: 029-accounts-backend
created: 2026-10-29T19:25:39Z
---

## Test Report: accounts-backend (bolt 1 of 2)

### Summary

- **Tests**: 331/331 pass in `supabase test db`, 33 of them new or changed:
  - `010_profiles`: 32 new checks
  - `002`: 1 new check
  - `001` and `002`: 3 checks rewritten
- **Rebuild**: `supabase db reset` rebuilds the database from the migrations and the
  seed.
- **Coverage**: pgTAP has no coverage tool. Planted bugs were used instead, and caught
  12 of 12 after one test was fixed.
- **No app code changed in this bolt**, so the app's 810 tests weren't rerun.

### Test Files

- [x] `backend/supabase/tests/database/010_profiles.test.sql` (32)
  - **The trigger**:
    - Google's full name (trimmed) and avatar are used.
    - The email's local part and `picture` are the fallbacks.
    - Long names are cut to 40 characters.
    - A blank name falls back to the email, and no name or email gives "Zema user".
    - Every user gets `contributor` and no other role.
    - The function has a fixed `search_path`, and the API roles can't call it.
  - **Reading**:
    - `anon` reads no profiles or roles.
    - A user reads only their own profile and roles.
  - **Updating**:
    - Renaming yourself works, and the name is trimmed.
    - 40 characters is accepted. 41, empty and spaces-only are refused.
    - The avatar and id can't be changed.
    - An update of every row changes only the user's own.
  - **Inserting and deleting**: profiles can't be inserted or deleted by a user.
  - **Roles**: a user can't make themselves a moderator, or change or delete their
    role.
  - **As the owner**:
    - The other user's name is unchanged.
    - The profile is still there.
    - Refused updates kept the last good name.
  - **Deleting the auth user** removes the profile and the roles.
- [x] `backend/supabase/tests/database/001_catalog_schema.test.sql`
  - The table list includes `profiles`.
  - The only write policy is `profiles` UPDATE.
- [x] `backend/supabase/tests/database/002_read_policies.test.sql`
  - Six catalog read policies.
  - No policy on reports or contributions.
  - `user_roles` has exactly one policy: SELECT for `authenticated`.

### End-to-End Check (real auth server, local backend)

A user was signed up through `/auth/v1/signup` with Google-style metadata, using the
anon key, which was never printed. With that user's token, through the API:

- **Profile**: `Almaz Ayana` (trimmed from `"  Almaz Ayana "`), with the avatar.
- **Roles**: `contributor`.
- **Rename**: 204, stored as `Almaz A.`, trimmed.
- **Changing the avatar**: `42501 permission denied`.
- **Adding `moderator`**: `42501 permission denied`.
- **`anon` reading profiles**: `[]`.
- **Deleting the auth user** left 0 profile and role rows.

### Planted Bugs (12; each planted on the local database, tested, then undone)

- **Caught on the first run (11)**:
  - profiles readable by all
  - avatar writable
  - roles readable by all
  - roles writable (also caught by 001 and 002)
  - profiles deletable (also caught by 001)
  - no length check
  - no trim on update
  - no email fallback
  - no `picture` fallback
  - no role on sign-up
  - the trigger callable by the API
- **Missed at first: the update policy changed to "any row"**
  - The test renamed the other user with `WHERE id = …`. Postgres also applies the
    read policy to the rows that a `WHERE` reads, so the read policy hid the bug.
  - An update with no `WHERE` reads no column, and would rename everyone.
  - The test now runs that unfiltered update and checks that only the user's own row
    changed. It now catches the bug.
- **After restoring**: 331/331 pass.

### Acceptance Criteria Validation

- ✅ **A new auth user gets a profile and the `contributor` role**: pgTAP, plus the
  real sign-up path.
- ✅ **Own profile and roles only; `anon` reads neither**: pgTAP and the API.
- ✅ **Only your own `display_name` can change, 1–40 characters, trimmed**: pgTAP and
  the API.
- ✅ **Nobody changes roles, avatar or id through the API**: pgTAP and the API.
- ✅ **Deleting the auth user removes the profile and roles**: pgTAP and the API.
- ✅ **`db reset` and `test db` pass**, with the earlier tests unchanged except the
  deliberate guard updates.
- ✅ **The Google provider comes from env variables, and `start` works with them
  unset**: checked in Stage 2.
- ✅ **The setup guide is written**. The key scan runs before the commit.

### Issues Found

- The missed update-policy bug above. The test is fixed.

### Notes

- **Real Google sign-in** isn't testable until the Google Cloud clients exist. It is
  checked in bolt 032.
- The e2e test user was deleted. The local database holds only the seed.
