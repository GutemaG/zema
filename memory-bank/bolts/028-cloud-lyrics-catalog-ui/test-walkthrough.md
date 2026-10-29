---
stage: test
bolt: 028-cloud-lyrics-catalog-ui
created: 2026-10-29T14:41:44Z
---

## Test Walkthrough: cloud-lyrics-catalog-ui (bolt 7 of 7)

### Results

| Suite | Tests |
|-------|-------|
| App | 810 (21 new) |
| `zema_core` | 201 |
| `zema_data` | 28 (1 changed) |
| Database (`supabase test db`) | 298 (10 new) |

- `flutter analyze` is clean and `dart format` changes nothing.
- The iOS simulator build passes.

### New and Changed Tests

- **Database**
  - **`009_report_ids`** (10):
    - a report with an ID is stored, with the ID kept
    - a repeat answers with the first report's id and stores nothing
    - a repeat at the daily limit is accepted, while a new report at the limit is
      refused
    - repeats aren't counted
    - the same ID from another install is a separate report
    - no ID works as before
  - **`003`**: the privilege check names the 6-argument signature.
  - **`001`, `003` and `009`** now clear `reports` inside their rolled-back
    transaction. Bolt 027's emulator reports in the local database had broken
    their counts.
- **`zema_data`**: `report_id` is sent when given, and left out otherwise.
- **App**
  - **`schema_test`**: v6.
  - **`migration_test`**: v5 → v6 gives each waiting report its own v4 UUID, keeping
    every field. The generated tests also cover 1–5 → 6.
  - **`reports_dao_test`**: reads back the ID.
  - **`report_sender_test`** (+3):
    - each send gets a new UUID
    - a report queued after a timeout is resent with the ID of its first try
    - a queued report keeps its ID across failed flushes
  - **`random_uuid_test`** (3): the v4 format; the version and variant bits set
    whatever the random bytes; 1,000 IDs all different.
  - **`community_row_test`** (8):
    - newest first, with both badges and the artist
    - at most 10, with ties sorted by title
    - a card opens Song detail at `/home/song?id=…`, and Back returns to Home
    - an empty index hides the row, and so does a build with no backend
    - an index refresh updates the row in place
    - 1.3× text, light and dark
  - **`catalog_search_test`** (+1): 5,000 songs searched within the keystroke budget.
    The slowest keystroke took 8 ms on the Mac.

### Planted Bugs

- **App: 17, of which 15 were caught on the first run.**
  - **"Queued with a new ID"**: the timeout test compared the queued ID with the one
    the flush sent, and both were the new one. The fake now records the ID of every
    try, and the test checks that the first try's ID is the one queued and resent.
  - **"Ties unsorted"**: the tie test's songs already came from the database in title
    order. The tie song now has an ID that sorts last.
  - Both are now caught.
  - One run hung after its failure and was stopped, as in earlier bolts.
- **Database: 5, of which 4 were caught.** Each bug was planted with `create or
  replace` on the local database, then pgTAP ran, then the function was restored.
  - **Not caught**: the "two copies at once" fallback, after `on conflict do
    nothing`. One test session can't produce the race, because the repeat lookup
    finds the first copy before the insert. It is reviewed, not tested.

### Emulator Check (Android, local backend)

- **The v5 → v6 upgrade on a real database**:
  1. With the bolt 027 build, I paused the gateway and made a report, which was
     queued.
  2. I installed this build. The waiting report got the UUID
     `3563f50c-0027-4bba-…`.
  3. After unpausing, one row reached the server with that `client_id`.
- **Story 009, bolt 027's duplicate case**:
  1. I paused the gateway, opened Galatoomi from the Home row, and reported Wrong
     words. It was queued with `4d946cfc-…`.
  2. On unpause, the held-up request landed.
  3. On restart, the queue resent the same ID. The server kept **one row**, and the
     phone's queue is empty.
  - In bolt 027 this case made two rows.
- **Story 008**:
  - Home shows "New lyrics from the community" with three cards: the letter tile,
    the Synced badge, the title and the artist.
  - Tapping Galatoomi opened Song detail with the Home tab selected, and Back
    returned to Home.
  - All three seed songs are synced, so Text only shows only in the widget tests.

### Intent Done-When Checks

| Check | Result |
|-------|--------|
| Lyrics for a linked song load from the backend | ✅ Galatoomi's album was changed on the server (version 17 → 18). After pull to refresh, Song detail fetched `get_song` again and showed "Server edit check". Reverted afterwards (version 19) |
| A song viewed once shows offline | ✅ Galatoomi showed from the cache with the gateway paused; also checked in bolts 024 and 026 |
| Cloud search < 1 s on 3G | ✅ **Now measured.** A throttling proxy on the Mac (384 kbit/s, 100 ms each way) sat between the emulator and the backend. In the app, `search.catalog` took 247, 352, 527, 528 and 621 ms. Straight `search_songs` calls with curl, each on a new connection, took 0.23–0.26 s |
| The 003 search queries match on the server | ✅ pgTAP `004_search_parity` passes |
| Local search < 100 ms per keystroke (5,000 songs + 1,000 tracks) | ✅ 5,000 catalog titles: at most 8 ms per keystroke (new test). 1,000 tracks: the `library_search_test` budget passes. Both timed on the Mac, not the phone |
| Index < 500 KB compressed for 5,000 songs | ✅ **347 KB** with gzip (default level), from 1.19 MB of JSON. The 5,000 songs had random Ge'ez titles and Latin names, which compress worse than real text, and were rolled back |
| Opening a cached song < 300 ms | ✅ the timing test in `catalog_lyrics_repository_test` passes |
| RLS tested with pgTAP; 5 reports a day | ✅ `002_read_policies` and `003`/`009` pass |
| Only the anon key in the app; no key in the repo | ✅ checked by the key scan before the commit |

### Notes

- **Story 008's "Synced" badge** is readable, but faint against the letter tile in the
  light theme. A design pass could give it more contrast.
- **The throttled config copy** (it held the local key) and the proxy were removed
  from the scratchpad after the check. The normal build is reinstalled.
- **I deleted the 5 test reports** from bolt 027's check in the local database, so
  the server counts start from zero.
