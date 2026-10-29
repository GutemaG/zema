---
stage: plan
bolt: 029-accounts-backend
created: 2026-10-29T19:14:00Z
---

## Implementation Plan: accounts-backend (bolt 1 of 2)

### Objective

- **Story 001, profiles and roles**: every new auth user gets a profile (display name
  and avatar from Google) and the `contributor` role. Users read their own profile
  and roles, and can change only their own display name.
- **Story 002, Google auth config**: the local Supabase Auth has the Google provider,
  configured from environment variables so no secret is committed, plus a guide for
  creating the Google Cloud OAuth clients.

### Deliverables

#### Story 001: Migration `20261029060000_profiles.sql`

- **`public.profiles`**
  - `id uuid primary key references auth.users on delete cascade`
  - `display_name text not null`, with a check: trimmed, 1–40 characters
  - `avatar_url text` (nullable)
  - `created_at` and `updated_at`
  - RLS on
- **`profiles_before_update` trigger**: trims `display_name` and sets `updated_at`.
  The check then refuses an empty or over-long name.
- **`handle_new_user()`**, a `security definer` trigger on `auth.users` insert, run as
  the owner with a fixed `search_path`:
  - **Name**: the first non-blank of `full_name`, `name`, and the email's local part
    from `raw_user_meta_data` (or `email`), trimmed and cut to 40 characters. The last
    fallback is `Zema user`.
  - **Avatar**: `avatar_url`, else `picture`.
  - **Role**: inserts `(id, 'contributor')` into `user_roles`, ignoring a repeat.
- **Backfill**: auth users that already exist get a profile and the role. There are none
  locally, but it keeps the migration safe on any database.
- **Policies**
  - `profiles`: `select` for `authenticated` where `id = auth.uid()`. `update` for
    `authenticated` where `id = auth.uid()`, checked again with `with check`.
  - `user_roles`: `select` for `authenticated` where `user_id = auth.uid()`.
  - No policies for `anon`.
- **Grants**: writes stay revoked by bolt 019's defaults. A column grant,
  `update (display_name)` on `profiles` to `authenticated`, is the only write. Nobody
  can insert or delete profiles, change `id` or `avatar_url`, or write roles.

#### Story 001: pgTAP `010_profiles.test.sql`

The test users are made in `auth.users` inside the rolled-back transaction. The tests
act as them with `set local role authenticated` and `request.jwt.claims`.

- **The trigger**:
  - Google metadata gives the name and avatar.
  - With no name, the email's local part is used.
  - A 60-character name is cut to 40.
  - A name of only spaces falls back.
  - `picture` is used when there's no `avatar_url`.
  - The `contributor` role is added.
- **Reading**:
  - A user sees only their own profile and roles.
  - `anon` sees neither.
- **Updating**:
  - A user can rename themselves to a trimmed 1–40 name.
  - Empty, spaces-only or 41-character names are refused.
  - Another user's row is unchanged.
  - Changing `avatar_url` or `id` is refused (permission).
- **Roles**: a user can't insert, update or delete a role, including giving themselves
  `moderator`.
- **No inserts or deletes**: a user can't insert or delete profiles.
- **Cleanup**: deleting the auth user removes the profile and roles (cascade).

#### Story 002: Google provider and guide

- **`config.toml`**: an `[auth.external.google]` section.
  - `client_id` and `secret` come from `env(SUPABASE_AUTH_EXTERNAL_GOOGLE_CLIENT_ID)`
    and `env(SUPABASE_AUTH_EXTERNAL_GOOGLE_SECRET)`. The client ID is a comma-separated
    list of the web, Android and iOS client IDs, so Supabase accepts ID tokens from all
    three.
  - `skip_nonce_check = true`, which the native sign-in flow needs locally.
  - `enabled`: true if `supabase start` still works with the variables unset. If not,
    false, with the guide saying to switch it on. This is checked in Stage 2.
- **`backend/supabase/.env.example`** (committed, values empty): the two variable
  names. The real `.env` is already gitignored.
- **`docs/google-sign-in-setup.md`**:
  1. Create a Google Cloud project and the OAuth consent screen.
  2. Create the web client. Its ID and secret go in `supabase/.env`.
  3. Create the Android client, with the package name and the debug and release
     SHA-1. The guide includes the `keytool` and `gradlew signingReport` commands.
  4. Create the iOS client, with the bundle ID and the reversed client ID as a URL
     scheme.
  5. Where each ID goes:
     - in Supabase, the web, Android and iOS IDs, comma-separated
     - in the app's `config/*.local.json`, `googleWebClientId` and
       `googleIosClientId`, which bolt 032 reads
  6. How to restart the backend and check the provider is on.
  7. A reminder never to commit any of these values.
- **`backend/README.md`**: a short section linking the guide.

### Dependencies

- **Intent 004's schema**: `user_roles`, `app_role`, and the default privileges that
  revoke writes.
- **The local Supabase in Docker**: `supabase migration up` and `supabase test db`.
- **No Google Cloud project**: the provider config is checked only for starting
  cleanly. Real sign-in is checked in bolt 032, once the IDs exist.

### Technical Approach

- The trigger function lives in `public`, but is executable by no API role. It is
  owned by `postgres`, and `execute` is revoked from `public`, `anon` and
  `authenticated`.
- `auth.uid()` reads `request.jwt.claims.sub`, which pgTAP can set.
- The column-level grant is the guard, and the update policy limits which row. Both are
  tested.

### Acceptance Criteria

- [ ] A new auth user gets a profile with the Google name and avatar, or a fallback,
      and the `contributor` role
- [ ] Users read only their own profile and roles. `anon` reads neither
- [ ] Users change only their own `display_name`, to 1–40 trimmed characters
- [ ] Nobody can change roles, avatar or id through the API
- [ ] Deleting the auth user removes the profile and roles
- [ ] `supabase db reset` and `supabase test db` pass, with all earlier tests unchanged
- [ ] `config.toml` has the Google provider from env variables. `supabase start` works
      with them unset
- [ ] The setup guide is written, and the key scan finds no secrets
