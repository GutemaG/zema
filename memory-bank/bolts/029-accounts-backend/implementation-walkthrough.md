---
stage: implement
bolt: 029-accounts-backend
created: 2026-10-29T19:22:57Z
---

## Implementation Walkthrough: accounts-backend (bolt 1 of 2)

### Summary

- Every new auth user now gets a profile and the `contributor` role, from a trigger on
  `auth.users`.
- Users read only their own profile and roles, and can change only their own display
  name.
- The local Supabase Auth has the Google provider, configured from a gitignored
  `.env`. A guide explains the Google Cloud setup.

### Structure Overview

- **Schema**: one migration adds `profiles`, its triggers, the sign-up trigger and
  the policies.
- **Writes**: they stay revoked by bolt 019's default privileges. A column grant on
  `display_name` is the only new write.
- **Auth config**: in `config.toml`, with the values in `supabase/.env`.

### Completed Work

- [x] `backend/supabase/migrations/20261029060000_profiles.sql`
  - **`profiles`**: the name is trimmed and 1–40 characters. A before-update
    trigger trims it and sets `updated_at`.
  - **`initial_display_name`**: Google's full name, else its name, else the email's
    local part, else "Zema user", each cut to 40 characters.
  - **`handle_new_user`**: a `security definer` sign-up trigger with an empty
    `search_path`. The API roles can't call it. It makes the profile and adds the
    `contributor` role.
  - **Backfill**: users who already exist get both.
  - **Policies**: users read their own profile and roles, and update their own
    profile.
  - **Grant**: `update (display_name)` to `authenticated`.
- [x] `backend/supabase/config.toml`: an `[auth.external.google]` section.
  - The client IDs and secret come from `env()`.
  - `skip_nonce_check` is on for native sign-in.
  - The provider is enabled.
- [x] `backend/supabase/.env.example`: the two variable names, empty.
- [x] `docs/google-sign-in-setup.md`
  - the consent screen
  - the web, Android (SHA-1 commands) and iOS clients
  - where each value goes
  - restarting and checking
  - never committing the values
- [x] `backend/README.md`: a "Google sign-in" section, with a link to the guide.
- [x] `backend/supabase/tests/database/010_profiles.test.sql`: written now to check the
  migration (31 checks). It is described in the test stage.
- [x] `backend/supabase/tests/database/001_catalog_schema.test.sql` and
  `002_read_policies.test.sql`
  - These guards pinned "no policies on roles" and "no write policies". They now pin
    the new exact set: one write policy (`profiles` UPDATE) and one roles policy
    (SELECT for `authenticated`).
  - The policy names are compared as one joined string, because pgTAP's
    `results_eq` can't compare `pg_policies`' `name` columns (a collation error).

### Key Decisions

- **Provider enabled without `.env`**: `supabase start` works with the variables
  unset. Auth then gets the literal `env(…)` text and refuses every Google token,
  which is harmless. Filling in `.env` and restarting is all that's needed.
- **App IDs in their own file**: `config/google.local.json`, not
  `backend.local.json`, because `tool/backend_env.sh` rewrites that file. Flutter
  accepts more than one `--dart-define-from-file`, and bolt 032 will confirm it.
- **Names cut before trimming**: a name cut at 40 can end in a space, so it's trimmed
  again on insert.

### Deviations from Plan

- **One more test**: "a user cannot delete their profile" is a check that the delete
  is refused, rather than a step before the count. A refused delete aborts the
  transaction, so it has to be wrapped. That makes 31 checks.

### Dependencies Added

- None.

### Developer Notes

- **Restarting the backend** (`supabase stop` / `start`) is needed after editing
  `config.toml` or `.env`. `migration up` doesn't reload auth settings.
- **`db reset` was run**: the local database was rebuilt from the migrations and the
  seed, so the reports left from earlier emulator checks are gone.
