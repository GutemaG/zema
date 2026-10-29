---
stage: plan
bolt: 026-cloud-lyrics-catalog-ui
created: 2026-10-29T12:09:08Z
---

## Implementation Plan: cloud-lyrics-catalog-ui (bolt 5 of 7)

### Objective

Settings → Lyrics lets a listener get ready for a trip without a network (story 005,
FR-7):

- It shows how much storage the downloaded lyrics use.
- **Download all lyrics for offline** saves every approved song, with progress and
  Cancel.
- **Clear downloaded lyrics** removes them, after a confirmation. Track links and the
  song index stay.

### Deliverables

- **`CachedSongsDao`**
  - **`watchUsage()`**: the number of cached songs and the bytes their documents
    take, from one `count(*)` / `sum(length(document))` query.
  - **`clear()`**: deletes every cached song.
- **`CatalogLyricsRepository`**
  - **`download(id)`**: the same path as opening a song.
    - A song already cached at the index's version is skipped, with no network call.
    - Otherwise it is fetched and saved.
    - Unlike opening a song, a failure is thrown even when an old copy exists, so
      Download all can report it.
  - **`clearCache()`**: empties Drift and the in-memory copies, so nothing cleared is
    still served.
- **`LyricsDownloader`** (`features/catalog/application/lyrics_download.dart`), a
  kept-alive Notifier, so a download goes on after leaving Settings.
  - **State**: idle, or running with done/total; then finished, cancelled, or failed
    with the `ZemaFailure`.
  - **`start()`**:
    1. It refreshes the index if it is stale (the 6 h rule), and goes on with the
       saved index if that fails.
    2. It downloads in batches of 4 at a time.
    3. Cancel is checked between batches. A batch that has started finishes, so no
       song is saved half-way.
    4. A failure stops the download with a message and keeps every song that
       finished.
    - Calling `start()` while running does nothing.
  - **`cancel()`**.
  - **`clear()`**: clears the cache through the repository and invalidates
    `songProvider`, so an open song is re-read. It isn't offered while a download
    runs.
- **Settings → Lyrics** (`LyricsSettingsGroup`), new rows below the existing ones:
  - **Downloaded lyrics**: "12 songs · 340 KB", or "None yet".
  - **Download all lyrics for offline**:
    - While it runs, the row shows "12 of 40", a progress bar and Cancel.
    - It finishes with "All lyrics downloaded", or "Download cancelled: 12 of 40
      saved".
    - A failure shows "Download stopped: check your connection", with the count
      saved.
    - In a build with no backend, the row is disabled with "Not available in this
      build".
  - **Clear downloaded lyrics**:
    - It opens a confirmation dialog: "Clear downloaded lyrics? Songs will download
      again when you open them online. Your matched songs stay matched."
    - The row is disabled when nothing is downloaded or a download is running.
  - **New strings** go in `app_en.arb`, with English fallback for am, om and ti.
- **Byte formatting**: a small `formatBytes` helper (B, KB, MB, one decimal), with
  tests.

### Dependencies

- Bolt 024: `CachedSongsDao`, `CatalogLyricsRepository`, `songProvider`.
- Bolt 023: the index refresher and `catalogEntriesProvider`.

### Technical Approach

- **The count of songs to download** comes from the saved index, so the total is known
  before anything is fetched.
- **Songs already up to date count as done** at once, so a second Download all
  finishes almost immediately.
- **No background service**: that is out of scope. The download lives as long as the
  app runs, and progress shows again on returning to Settings.

### Acceptance Criteria → Tests

| Criterion | Test |
|-----------|------|
| Storage used shows | DAO test (count and bytes, updating after a save and a clear); widget test for the row |
| Download all caches every approved song, with progress | downloader test: every index song is cached, and progress counts up in batches; widget test: "n of m" and the bar while held, then done |
| Can be cancelled | downloader test: cancel after the first batch keeps that batch and stops; widget test |
| A failure stops with a message and keeps what finished | downloader test; widget test for the message |
| Leaving Settings mid-download | widget test: leave, the download continues, and on return the progress shows |
| Clear removes cached lyrics; links and index stay | repository/downloader test: cache empty, index and links unchanged, memory copy gone; widget test with the dialog (Cancel keeps, Clear removes) |

### Emulator Check

1. Settings → Lyrics shows the storage used, about 1 song from earlier bolts.
2. Download all: progress, then 3 songs, and the storage grows.
3. Stop the backend, then open each song. Expected: all show.
4. Clear, then confirm. Expected: none yet. Galatoomi stays linked, and opening it
   offline shows C07.
5. Start the backend again.
