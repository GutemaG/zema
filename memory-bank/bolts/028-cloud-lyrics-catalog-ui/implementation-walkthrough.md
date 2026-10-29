---
stage: implement
bolt: 028-cloud-lyrics-catalog-ui
created: 2026-10-29T14:12:27Z
---

## Implementation Walkthrough: cloud-lyrics-catalog-ui (bolt 7 of 7)

### Summary

- **Story 009**: each report carries an ID made by the app.
  - The server answers a repeat from the same install with the first report's id.
    It stores nothing more and doesn't count the repeat for the daily limit.
  - The app keeps the ID with a queued report, so a resend after a timeout is
    safe.
- **Story 008**: Home's last row, "New lyrics from the community", lists the 10 songs
  approved most recently, with a Synced or Text only badge.
  - Tapping a card opens Song detail in the Home tab.

### Files

#### Backend

- **`migrations/20261029050000_report_ids.sql`**
  - Adds `reports.client_id uuid`, with a partial unique index on
    `(install_hash, client_id)`.
  - `submit_report` is dropped and re-created with a 6th parameter,
    `report_id uuid default null`. The 5-argument call still resolves through the
    default.
  - **A repeat** is looked up after the input checks and the hashing, and before
    the limit.
  - **The insert** uses `on conflict … do nothing`. If two copies race, the second
    gets the first one's id.
  - Grants are as before. It is applied to the local database with
    `supabase migration up`.
- **`tests/database/003_submit_report.test.sql`**: the privilege check names the new
  6-argument signature.

#### Packages

- **`zema_core` `CatalogRepository.report`**: gets `String? reportId`, with the
  contract documented.
- **`zema_data`**: sends `report_id` when it is given.

#### App

- **`shared/random_uuid.dart`** (new): `randomUuid()`, a v4 UUID from
  `Random.secure`.
- **Drift v6**
  - `queued_reports.report_id` (text, not null).
  - `from5To6` rebuilds the table with `TableMigration`. Waiting rows get a random
    v4 UUID made in SQL (`randomblob`), so a report queued in v5 keeps one ID from
    then on.
  - The schema dump is `drift_schema_v6.json`, with `schema_v6.dart` generated.
- **`reports_dao.dart`**: `add(report, reportId:)`. `all()` returns
  `(id, reportId, report)`.
- **`report_sender.dart`**
  - `send` makes one ID, sends with it, and queues with it when offline.
  - `flush` sends each queued report with its stored ID.
- **`catalog_index.dart`**: `newLyricsProvider`, the index by `approvedAt` (newest
  first, then title), 10 songs. It is derived from `catalogEntriesProvider`, so it
  follows index refreshes.
- **`track_art.dart`**: the letter placeholder became a public `LetterTile`. Its look
  is unchanged, and `TrackArt` uses it.
- **`home_rows.dart`**
  - **`CommunityLyricsRow`**: `_HomeRow`/`_HomeCard` with a `LetterTile`.
  - **`_SyncBadge`** at the art's bottom start:
    - "Synced": `soft` with `accentText`
    - "Text only": `surface` with `muted`
  - The card text is the title and the artist.
  - **Tap**: `AppRoutes.song(id, base: home)`.
  - Hidden when the index is empty.
- **`home_screen.dart`**: the row comes after Playlists.
- **`router.dart`**: Home gets the shared song, album and artist child routes, so
  Song detail stays in the Home tab.
- **`app_en.arb`**: `homeNewLyrics`. The badge reuses `songRecordingSynced` and
  `songRecordingTextOnly`.

### Checked

- `flutter analyze lib` is clean, and `dart format` is applied.
- **`zema_core` 201 and `zema_data` 28 pass.**
- **App: 772 tests pass.** The ones left need stage 3 changes:
  - `reports_dao_test` and `report_sender_test` need the new `reportId` argument.
  - `schema_test` still expects v5.
- **`app_shell_test`** failed only in the full run. It was the first file loaded when
  the test compiler crashed on those broken files. On its own, all 18 of its tests
  pass.

### Notes

Stage 3 covers:

- the pgTAP `009_report_ids` test, plus `supabase test db`
- a `zema_data` test that `report_id` is sent
- the v5 → v6 migration, and the DAO and sender with IDs
- the `randomUuid` format
- the Home row widget tests
- the emulator checks
- the intent's done-when checks
