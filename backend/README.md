# backend

The Zema lyrics catalog: a [Supabase](https://supabase.com) project (Postgres, API and
Row Level Security), kept in version control and run locally during development.

```text
backend/
  supabase/
    config.toml        local project settings (project ID "zema")
    migrations/        the schema, applied in order; the only source of truth
    tests/database/    pgTAP tests, run with `supabase test db`
    seed.sql           GENERATED from seed/ (see Seed)
  seed/                songs to load: index.json + LRC files
  bench/               timing scripts, run by hand
```

## Requirements

- Docker, running
- Node.js (for `npx`); the Supabase CLI is run with `npx supabase`, nothing to install

The first `start` downloads the Docker images (about 1–2 GB).

## Commands

Run these from `backend/`:

| Command | What it does |
|---------|--------------|
| `npx supabase start` | Starts the local backend and applies the migrations |
| `npx supabase db reset` | Rebuilds the database from the migrations (loses local data) |
| `npx supabase test db` | Runs the pgTAP tests |
| `npx supabase status` | Shows the local URLs and keys |
| `npx supabase stop` | Stops the containers |

Local addresses: API `http://127.0.0.1:54321`, Studio `http://127.0.0.1:54323`,
database `postgresql://postgres:postgres@127.0.0.1:54322/postgres`. The Android
emulator reaches the API at `http://10.0.2.2:54321`.

To run the app against the local backend, from `apps/mobile/`:

```text
tool/backend_env.sh          # writes config/backend.local.json (anon key, gitignored)
flutter run --dart-define-from-file=config/backend.local.json
```

For a real phone, pass your computer's address: `tool/backend_env.sh http://192.168.1.20:54321`.

Only Postgres, the API, auth and Studio run locally; realtime, storage, edge functions,
analytics and the mail catcher are turned off in `config.toml` until they are needed.

## Rules

- Change the schema only with a new migration file; never edit the database by hand
  in Studio.
- Keys: the app uses only the public anon key. The service (secret) key is for local
  scripts such as the seed, read from `npx supabase status`; never commit any key.
- Every table has Row Level Security on. Listeners can read approved songs only;
  writes go through checked functions (see the migrations).

## Schema

| Table | Holds |
|-------|-------|
| `songs` | Title, transliteration, artist, album, status (draft / approved / rejected), version |
| `sections`, `lines` | A song's verses and choruses, and their lines |
| `play_order` | The sung order of sections (repeats included) |
| `recordings` | Performances of a song: source, artist, duration, offset |
| `sync_timings` | One start time per sung line, per recording |
| `reports` | "Wrong lyrics" reports for moderators |
| `user_roles`, `contributions` | For accounts and contributions (later intents) |

## Seed

`npx supabase db reset` loads `supabase/seed.sql`: the songs in `seed/` (an
`index.json` plus one LRC file per song), approved. To add a song:

1. Put its LRC file in `seed/` and add an entry to `seed/index.json`:
   `{"id": "slug-id", "file": "slug-id.lrc", "transliteration": "…", "durationMs": 43000}`
   (optional `"status"`: `approved`, the default, `draft` or `rejected`).
2. Regenerate: `cd packages/zema_core && dart run tool/generate_seed_sql.dart`
   (bad entries are skipped and listed).
3. `npx supabase db reset`.

`seed.sql` calls `seed_song(document)`, which leaves an identical song untouched, so the
same file can be run again on a hosted project (`psql` or
`npx supabase db push --include-seed`). Only the service role may call it. The app reads
a song with `get_song(id)`, in the JSON shape `zema_core` uses, and the list of
approved songs (without lyrics) with `song_index()`.

The three songs there now are placeholders written for Zema to test synced lyrics; they
need review by a native speaker before any release.

## Search

`search_songs(query)` searches approved songs by title, transliteration, artist and
lyric line, with the same spelling folds and transliteration matching as the app.
The rules are generated from `zema_core`, never edited by hand:

```text
cd packages/zema_core && dart run tool/generate_search_sql.dart
```

This rewrites `migrations/20261029020000_search_rules.sql` and the parity test
`tests/database/004_search_parity.test.sql` (zema_core's own answers for the same
inputs). A Dart test fails if either file is stale. `bench/search_bench.sql` times the
search on 5,000 synthetic songs.

A song's `version` increases whenever its text, sections, recordings or timings change,
so phones know when their cached copy is out of date.
