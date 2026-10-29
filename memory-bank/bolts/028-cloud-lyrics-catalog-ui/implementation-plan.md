---
stage: plan
bolt: 028-cloud-lyrics-catalog-ui
created: 2026-10-29T14:01:41Z
---

## Implementation Plan: cloud-lyrics-catalog-ui (bolt 7 of 7)

### Objective

- **Story 008, Home community row (FR-10)**: Home shows the songs most recently
  approved in the catalog, each with a Synced or Text only badge. Tapping one opens
  Song detail.
- **Story 009, a report is stored once**: added after bolt 027's emulator check. A
  report that timed out had still reached the server, and the queued copy was sent
  again. Each report now carries an ID made by the app, and the server ignores a
  repeat of it.
- **Then the intent's done-when checks**, from its goals and non-functional
  requirements.

### Deliverables

#### Story 009: Report IDs (backend, then app)

- **Migration `20261029050000_report_ids.sql`**
  - `reports.client_id uuid`, nullable for reports from before this change.
  - A unique index on `(install_hash, client_id)` where `client_id` is not null.
    The same ID from another install is a different report.
  - `submit_report` is replaced (dropped and re-created, with the same grants)
    with a new last parameter, `report_id uuid default null`:
    - It checks the input as before, then hashes the install ID.
    - **A repeat**: if this install already stored `report_id`, it returns that
      report's id. Nothing is stored, and the call comes before the daily limit,
      so the repeat isn't refused or counted.
    - **Otherwise**: the limit check, then the insert. On a race between two copies,
      `on conflict do nothing` keeps one, and the existing id is returned.
- **pgTAP `009_report_ids.test.sql`**:
  - a repeat stores nothing and succeeds
  - the repeat returns the same id
  - the repeat at the limit (after 5 reports) still succeeds, and the count stays 5
  - the same ID from another install is stored separately
  - no ID still works as before
  - the old 5-argument call still works, through the default
- **`zema_core` / `zema_data`**
  - `CatalogRepository.report` gets `String? reportId`, sent as `report_id`.
  - A `zema_data` test checks the parameter is sent.
  - The fake records it.
- **App**
  - **Drift v6**: `queued_reports.report_id` (text). The migration gives existing
    rows a random UUID in SQL, so a report queued in v5 keeps one ID from then on.
  - **`randomUuid()`** (UUID v4 from `Random.secure`) in `lib/shared/`.
  - **`ReportSender`**:
    - `send` makes the ID once and uses it for the first try.
    - If queued, the report keeps that ID.
    - `flush` sends each queued report with its stored ID.

#### Story 008: Home community row

- **`newLyricsProvider`**: the saved index sorted by `approvedAt`, newest first, ties
  by title, taking 10. It comes from `catalogEntriesProvider`, so the row updates in
  place when the index refreshes.
- **`CommunityLyricsRow`**, in `home_rows.dart`:
  - It uses the existing `_HomeRow` and `_HomeCard`, under the header "New lyrics
    from the community", with no See all. There is no list screen to open.
  - **The card art**: a `tile` square with the title's first letter.
  - **The badge**: at the bottom of the art, either "Synced" (`soft` with
    `accentText`, the design system's badge) or "Text only" (`surface` with
    `muted`).
  - **The card text**: the title and the artist.
  - **Tap**: opens Song detail in the Home tab. Home gets the shared song, album
    and artist child routes, like Search, so Back returns to Home.
  - Hidden when the index is empty, so a build with no backend never shows it.
- **Where**: the last row on Home, after Playlists. Like the other rows, it isn't
  shown while the library is being scanned.
- **Strings**: `homeNewLyrics`, and the existing Synced and Text only strings
  reused. am, om and ti fall back to English.

### Intent Done-When Checks (test stage)

| Check | How |
|-------|-----|
| Lyrics for a linked song load from the backend | emulator: link → lyrics from the local backend (and a server-side change shows after refresh) |
| A song viewed once shows offline | emulator, backend gateway paused (done in 024/026; repeated) |
| Cloud search < 1 s on 3G | a small throttling proxy on the host (≈ 384 kbit/s, 150 ms each way) between the emulator and the backend; read `search.catalog` ms from the log. The emulator's `umts` setting didn't throttle host traffic in 025 |
| The 003 search queries match on the server | pgTAP `004_search_parity` |
| Local search < 100 ms per keystroke (5,000 songs, 1,000 tracks) | existing `library_search_test` / `catalog_search_test` timing tests |
| Index < 500 KB compressed for 5,000 songs | in a rolled-back transaction, add 5,000 songs, gzip `song_index()`'s JSON, and measure |
| Opening a cached song < 300 ms | existing timing test in `catalog_lyrics_repository_test` |
| RLS tested with pgTAP; only the anon key in the app; 5 reports a day | `supabase test db`; the key scan; the report tests |

### Acceptance Criteria → Tests

| Criterion | Test |
|-----------|------|
| 008: row of most recent with badge | provider test (order, ties, limit 10); widget test (cards in order, both badges) |
| 008: tap opens Song detail | widget test: inside the Home tab, and Back returns to Home |
| 008: empty index hides the row | widget test |
| 008: index refresh updates the row | widget test: replace the index; the new song shows without leaving Home |
| 008: 1.3× text, light and dark | widget test |
| 009: repeat stores nothing and succeeds; not counted | pgTAP |
| 009: queued report keeps its ID | sender tests: timeout, queue, flush with the same ID; v5 → v6 migration gives old rows an ID |
| 009: emulator | repeat bolt 027's gateway-paused report: one row on the server |
