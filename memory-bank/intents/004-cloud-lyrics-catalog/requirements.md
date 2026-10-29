---
intent: 004-cloud-lyrics-catalog
phase: inception
status: units-defined
created: 2026-10-23T22:16:40Z
updated: 2026-10-29T05:57:07Z
---

# Requirements: Cloud Lyrics Catalog

> Source: `docs/roadmap.md` Stage 4 · screens: `docs/screens.md` S05, S06, S07
> (Recordings), S08, S28, C07 · Complexity ★★★☆☆ · First backend (Supabase), run locally
> during development.

## Intent Overview

Replace the bundled sample lyrics with a shared online catalog (read-only for listeners),
while keeping the app fully usable offline. The app keeps a light index of every approved
song (no lyrics) for automatic linking and title search, and downloads each song's lyrics
when it is opened or linked, caching them for offline use. Listeners can report wrong
lyrics without signing in. Writing lyrics (contributions, moderation) stays out of scope
until 005/006, but the schema already supports it.

## Business Goals

| Goal | Success Metric | Priority |
|------|----------------|----------|
| Real catalog in the app | Lyrics for a linked song load from the backend | Must |
| Offline-first | A song viewed once shows its lyrics later with no internet | Must |
| Fast on slow networks | Cloud search results < 1 s on a 3G-class connection | Must |
| Same search everywhere | The 003 search test queries return the same songs on the server | Must |

---

## Functional Requirements

### FR-1: Backend project and schema (`backend/`)
- **Description**: A Supabase project in `backend/supabase/` (CLI config, SQL
  migrations, seed, tests), run locally with the Supabase CLI in Docker. Tables: songs
  (title, transliteration, artist, album, status), sections and lines, play order,
  recordings (source, artist, duration, offset), sync timings, reports, plus
  contributions and user roles for 005/006 (created, not yet written to). Every song has a
  stable text ID (slug) so links on phones keep working.
- **Acceptance Criteria**: `supabase db reset` builds the schema from migrations and the
  seed with no errors; a schema test lists the expected tables.
- **Priority**: Must

### FR-2: Row Level Security
- **Description**: Anyone (anonymous) can read approved songs and their sections,
  recordings and timings; nothing else is readable. No anonymous writes, except creating
  a report through FR-7's function.
- **Acceptance Criteria**: Database tests (pgTAP) prove that, as the anonymous role,
  draft or rejected songs and all reports, contributions and roles cannot be read, and
  direct inserts, updates and deletes on every table fail.
- **Priority**: Must

### FR-3: Server-side search
- **Description**: A search function over approved songs: titles, transliterations,
  artists and lyric lines, with the same spelling folding and transliteration rules as
  `zema_core`. The rules are generated into SQL from `zema_core`'s rule tables, not
  rewritten by hand, so the two cannot drift.
- **Acceptance Criteria**: A parity test runs the 003 search test queries (e.g.
  "kidist", "ቅድስት", "ቅዱስት") against both `zema_core` and the server and gets the same
  songs; a lyric-line query returns the song with its matching line.
- **Priority**: Must

### FR-4: Seed script
- **Description**: A script that loads songs from a folder of files into the backend,
  in the formats the app already reads (LRC plus an index with ID, title,
  transliteration, artist, album). It starts with the three placeholder songs, which
  move from the app to the backend; running it twice changes nothing.
- **Acceptance Criteria**: After seeding, the three songs are readable with the same IDs,
  sections, play order and timings as the bundled versions (compared in a test).
- **Priority**: Must

### FR-5: `packages/zema_data` Supabase repository
- **Description**: A new pure-Dart package in the pub workspace with the Supabase
  implementation of the lyrics repository: fetch the song index, fetch a song with its
  recordings and timings, search, and submit a report. Backend errors become
  `ZemaFailure`s, never raw exceptions.
- **Acceptance Criteria**: Tests against the local backend cover each call; a test with
  the backend stopped gets a failure, not a crash.
- **Priority**: Must

### FR-6: Song index on the phone
- **Description**: The app keeps an index of every approved song (ID, title,
  transliteration, artist, album, synced or not; no lyrics) in Drift. It refreshes when
  the app starts online, at most every 6 hours, and on pull-to-refresh in Search.
  Automatic linking (003 FR-10) and title search use this index, so both work offline.
- **Acceptance Criteria**: With no network, auto-linking and title search still work
  from the last index; a song removed from the catalog drops out on the next refresh,
  and its links show "No lyrics" rather than an error.
- **Priority**: Must

### FR-7: Lyrics cache and offline use
- **Description**: A song's full lyrics, recordings and timings are downloaded when it is
  opened or linked, saved in Drift, and served from there afterwards (refreshed when the
  song's version changes). Settings shows the storage used, "Download all lyrics for
  offline" with progress, and "Clear downloaded lyrics".
- **Acceptance Criteria**: A song viewed once shows offline after a restart; Download all
  caches every approved song and can be cancelled; Clear removes them but keeps links.
- **Priority**: Must (cache) / Should (Download all, storage, Clear)

### FR-8: Report wrong lyrics
- **Description**: "Report wrong lyrics" from Song detail and the Now Playing lyrics
  options: a reason (wrong words, wrong timing, wrong song, other) and an optional note.
  Guests can report; a report is limited to 5 per device per day and stored for
  moderators. Offline reports are queued and sent later.
- **Acceptance Criteria**: A report is stored with the song, recording, reason and note;
  the sixth report in a day is refused with a friendly message; reports are not
  readable by anyone anonymous.
- **Priority**: Should

### FR-9: Song detail — Recordings tab
- **Description**: A third tab listing the song's recordings: artist, source, duration,
  and Synced or Text only. The recording used for the lyrics view is marked.
- **Priority**: Should

### FR-10: Home — "New lyrics from the community"
- **Description**: A Home row of the most recently approved songs with a Synced or Text
  only badge; tapping one opens Song detail. Hidden when the index is empty.
- **Priority**: Could

### FR-11: Search merges the phone and the catalog
- **Description**: Search keeps its local groups (always, offline too) and adds the
  catalog: title matches come from the index, and lyric-line matches come from the
  server when online. When offline, the lyrics group shows a C07 offline note and
  falls back to lines of cached songs.
- **Acceptance Criteria**: Online, a line from an uncached song is found; offline, the
  note shows and local results are unaffected; typing stays responsive (local results
  never wait for the network).
- **Priority**: Must

---

## Non-Functional Requirements

### Performance
| Requirement | Metric | Target |
|-------------|--------|--------|
| Cloud search | Response on a 3G-class network (emulator `umts` speed) | < 1 s |
| Local search | Per keystroke with the index loaded (5,000 songs + 1,000 tracks) | < 100 ms |
| Song index | Download size for 5,000 songs, compressed | < 500 KB |
| Opening a cached song | Lyrics on screen | < 300 ms |

### Security
| Requirement | Standard | Notes |
|-------------|----------|-------|
| Authorization | Supabase RLS | All rules enforced server-side; tested with pgTAP |
| Keys | Only the public anon key in the app | No service key in the app or repo; local keys come from `supabase start` |
| Reports | Rate limit in the database function | 5 per device per day; device ID is a random install ID, not hardware |

### Reliability
| Requirement | Metric | Target |
|-------------|--------|--------|
| Offline | Lyrics for previously viewed songs | 100% available |
| Network errors | Failed fetches | Show a retry, never a crash; cached data still shows |

---

## Constraints

### Technical Constraints

**Project-wide standards**: Required standards will be loaded from memory-bank standards folder by Construction Agent

**Intent-specific constraints**:
- Introduces the first backend; schema must already support contributions and roles
  (used in 005/006) even if not written to yet.
- Development uses a local Supabase (CLI + Docker); the app reads the backend URL and
  anon key from build-time configuration (`--dart-define`), so switching to a hosted
  project later needs no code change. The emulator reaches the local backend at
  `10.0.2.2`.
- `zema_core` stays free of backend code; the Supabase client lives only in
  `packages/zema_data` and the app.
- Bolts stay small (1–3 stories).

### Business Constraints
- **Out of scope:** sign-in, writing lyrics (except reports), moderation tools, a hosted
  production backend.

---

## Assumptions

| Assumption | Risk if Invalid | Mitigation |
|------------|-----------------|------------|
| Supabase free/low tier is enough initially | Cost/limits | Monitor usage; cache aggressively |
| Anonymous reports are acceptable | Spam | Rate limit per device; revisit when sign-in exists (005) |
| A light index of all songs stays small | Large download | Measure at 5,000 songs; page or delta-sync if over target |
| The rule tables can be expressed in SQL | Search differs on the server | Generate SQL from Dart; parity test |

---

## Resolved Questions

| Question | Resolution | Date |
|----------|------------|------|
| How is the first lyrics catalog seeded? | Seed script loading files (LRC + index), starting with the 3 placeholder songs; real lyrics added later with permission | 2026-10-29T05:57:07Z |
| Can guests submit "wrong lyrics" reports? | Yes, rate-limited per device | 2026-10-29T05:57:07Z |
| Where does the backend run during development? | Local Supabase (CLI in Docker); hosted project later | 2026-10-29T05:57:07Z |
| How does the app know the catalog's songs? | A light index of all approved songs on the phone; lyrics downloaded on demand and cached | 2026-10-29T05:57:07Z |
| What happens to the bundled samples? | Moved to the backend via the seed; kept only as test fixtures | 2026-10-29T05:57:07Z |
| Scope of Should/Could features | All included: reports, Recordings tab, Download all, Home community row | 2026-10-29T05:57:07Z |
