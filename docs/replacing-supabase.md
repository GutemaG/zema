# Replacing Supabase with plain Postgres

How to run Zema's backend without Supabase: your own Postgres, with PostgREST for the
API and a small auth service of your own. This is option 2 of three. The others are
summarized at the end.

## What Supabase does for Zema today

| Part | What Zema uses | Supabase-only? |
|---|---|---|
| **Postgres** | Tables, about 70 SQL functions, triggers, RLS, `pgcrypto` and `fuzzystrmatch` in the `extensions` schema, pgTAP tests | No |
| **PostgREST** (`/rest/v1`) | Every app call: `.rpc(...)` and `.from(...)` in `packages/zema_data`. It sets `request.headers` (the IP for limits) and turns error code `PT429` into HTTP 429 | No: an open-source program that runs on its own |
| **GoTrue** (`/auth/v1`) | Google sign-in (`signInWithIdToken`), session refresh, sign-out; the `auth.users` table; `auth.uid()` | **Yes**: this is the part to replace |
| **Roles** | `anon`, `authenticated`, `service_role`: 35 `grant`s decide who may call what | No: plain Postgres roles |

Storage, Realtime and Edge Functions are not used.

The SQL depends on GoTrue in only a few places:

- `auth.uid()`: 14 calls (contributions, reviews, backups, profiles, fingerprints).
- `auth.users`: referenced by `profiles`, `user_roles`, `backups` and `contributions`.
  The trigger `on_auth_user_created` reads `email` and `raw_user_meta_data` (name,
  picture). `delete_account` deletes the user's row; the cascades do the rest.
  `set_moderator` finds a user by email.

## The new setup

```text
phone ──HTTPS──► reverse proxy (Caddy) ──► /rest/v1 ──► PostgREST ──► Postgres
                                       └─► /auth/v1 ──► auth service ─┘
```

The trick is to **keep Supabase's URL paths and token format**. Then the app's
`supabase_flutter` client keeps working: only the backend URL and key change.

## Steps

### 1. Postgres

Postgres 15 or newer, on a VPS (2 GB RAM and 40 GB disk is plenty to start) or a
managed Postgres. Create the extensions in an `extensions` schema:

```sql
create schema extensions;
create extension pgcrypto with schema extensions;
create extension fuzzystrmatch with schema extensions;
```

### 2. Roles

```sql
create role anon nologin;
create role authenticated nologin;
create role service_role nologin bypassrls;
create role authenticator login password '…' noinherit;
grant anon, authenticated, service_role to authenticator;
grant usage on schema public, extensions to anon, authenticated, service_role;
```

PostgREST logs in as `authenticator` and switches to the role named in the request's
token.

### 3. A small `auth` schema

Only what the migrations use, created **before** the migrations:

```sql
create schema auth;
create table auth.users (
  id uuid primary key default gen_random_uuid(),
  email text unique,
  raw_user_meta_data jsonb not null default '{}',
  created_at timestamptz not null default now()
);
create table auth.refresh_tokens (
  token_hash text primary key,
  user_id uuid not null references auth.users (id) on delete cascade,
  expires_at timestamptz not null
);
create function auth.uid() returns uuid language sql stable as $$
  select nullif(current_setting('request.jwt.claims', true)::json ->> 'sub', '')::uuid
$$;
grant usage on schema auth to anon, authenticated, service_role;
```

Deleting a user deletes their refresh tokens, so `delete_account` still signs them out
everywhere.

### 4. Migrations

Apply `backend/supabase/migrations/` in order. The Supabase CLI works against any
Postgres, so the same tool keeps track of what has run:

```text
npx supabase db push --db-url "postgresql://postgres:…@host:5432/zema"
```

Then load `seed.sql` with `psql`. Run the pgTAP tests with `pg_prove` against a test
copy.

### 5. PostgREST

```ini
db-uri = "postgresql://authenticator:…@localhost:5432/zema"
db-schemas = "public"
db-anon-role = "anon"
jwt-secret = "<at least 32 random characters>"
server-port = 3000
```

Behind the proxy at `/rest/v1`. The proxy must pass `X-Forwarded-For`, which the daily
limits read.

### 6. The auth service

A small HTTP service (Dart `shelf`, Node or Go; about 300 lines) at `/auth/v1`, answering
the same requests as GoTrue so `supabase_flutter` needs no changes:

| Request | What it does |
|---|---|
| `POST /token?grant_type=id_token` (`provider`, `id_token`) | Checks Google's ID token: signature (Google's public keys), issuer, expiry, and an audience that is one of Zema's client IDs. Finds or creates the `auth.users` row by email (with name and picture). Returns an access token and a refresh token |
| `POST /token?grant_type=refresh_token` | Swaps a valid refresh token for new tokens. Refresh tokens are used once |
| `POST /logout` | Deletes the session's refresh tokens |
| `GET /user` | The signed-in user |

The **access token** is a JWT signed with PostgREST's `jwt-secret`: `sub` (the user's
ID), `role: "authenticated"`, `email`, and an expiry of one hour. Store refresh
tokens hashed.

The response must have the same fields as GoTrue's (`access_token`, `token_type`,
`expires_in`, `expires_at`, `refresh_token`, `user`). Check it against the
`supabase_flutter` version in `pubspec.lock` with a test that signs in, refreshes and
signs out.

### 7. Keys

- **Anon key**: a JWT with `role: "anon"` and a long expiry, signed with the same
  secret. It goes in `apps/mobile/config/backend.prod.local.json` as before.
- **Service key**: a JWT with `role: "service_role"`, for the seed and fingerprint
  tools. Never in the app.

### 8. Moving the data

From the hosted project:

1. `pg_dump --data-only` of the `public` schema.
2. A copy of `auth.users` with only `id`, `email`, `raw_user_meta_data` and
   `created_at`. The IDs must stay the same, or contributions and backups lose their
   owners.

Users sign in again once, because their Supabase sessions don't carry over.

### 9. Running it

- Nightly `pg_dump` to storage off the server, and a restore you have tried once.
- Updates to Postgres, PostgREST and the OS.
- HTTPS certificates (Caddy renews them by itself).
- Watch disk use: the fingerprints grow fastest (see
  [fingerprint-storage.md](fingerprint-storage.md)).

## Effort

| Work | Time |
|---|---|
| Server, Postgres, roles, `auth` schema, migrations, PostgREST, proxy | 2–3 days |
| Auth service and its tests | 3–5 days |
| Checking the app end to end, moving the data | 1–2 days |
| **Total** | **about 1–2 weeks** |

## The other options

| Option | Effort | Notes |
|---|---|---|
| **1. Self-host Supabase** (its Docker Compose, the same stack that runs locally) | About a day | No code changes. You run more containers (about 4 GB of RAM) and keep them updated |
| **2. Postgres + PostgREST + own auth** (this document) | 1–2 weeks | Fewest moving parts that still need no app changes |
| **3. Postgres + own API server** | 3–5 weeks | An endpoint per function, and the `zema_data` repositories rewritten. Only worth it for server logic outside SQL |

Staying on hosted Supabase and moving to the Pro plan (8 GB) needs no work at all.
That is the simplest answer if the only problem is the free plan's 500 MB.
