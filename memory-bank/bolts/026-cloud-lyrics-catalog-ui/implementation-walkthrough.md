---
stage: implement
bolt: 026-cloud-lyrics-catalog-ui
created: 2026-10-29T12:16:47Z
---

## Implementation Walkthrough: cloud-lyrics-catalog-ui (bolt 5 of 7)

### Summary

Settings → Lyrics has three new rows:

- **Downloaded lyrics**: shows the storage used.
- **Download all lyrics for offline**: shows progress, with Cancel.
- **Clear downloaded lyrics**: asks for confirmation first.

The download keeps going after leaving Settings, and the progress shows again on
return.

### Files

- **`cached_songs_dao.dart`**
  - **`watchUsage()`**: `(songs, bytes)` from one query, `count(id)` and
    `sum(length(document))`. `length` counts characters, so it is close to the size
    on disk, not exact.
  - **`clear()`** deletes every row.
- **`catalog_lyrics_repository.dart`**
  - **`lyricsRepositoryProvider`** now gives `CatalogLyricsRepository`, so the
    downloader can call its new methods. No test overrode it.
  - **`download(id)`**:
    - A song the index doesn't list, or one cached at the index's version, is
      skipped with no network call.
    - Otherwise it is fetched and saved, and a failure is thrown even when an older
      copy exists.
  - **`clearCache()`** empties memory and Drift.
  - **The shared-fetch logic** moved into `_shared`, used by `document` and
    `download`.
- **`features/catalog/application/lyrics_download.dart`** (new)
  - **`LyricsDownload`**: status (idle, running, finished, cancelled, failed), done,
    total and failure.
  - **`LyricsDownloader`**, a Notifier kept alive by Riverpod's default.
    - **`start()`**:
      1. It does nothing while running.
      2. It sets running with total 0, which shows "Checking the song list…".
      3. It refreshes the index if stale, and logs and goes on if that fails.
      4. It reads the saved index and downloads in batches of `batchSize` (4).
      5. Each song counts when it finishes. A `ZemaFailure` in a batch stops the
         download after the batch, and every finished song is kept.
      6. Cancel is checked before each batch.
    - **`cancel()`**.
    - **`clear()`**: refused while running. It calls `clearCache` and invalidates
      `songProvider`.
  - **`lyricsUsageProvider`**.
- **`lyrics_settings_group.dart`**: new `_OfflineLyricsRows`, below the existing
  rows.
  - **Downloaded lyrics**: "12 songs · 340 KB", or "None yet".
  - **Download all**:
    - It is tappable unless running, or in a build with no backend.
    - While running, it shows a Cancel button, a progress bar (no value while
      checking) and "12 of 40".
    - The status line under the row reads "All lyrics downloaded", "Cancelled: …
      saved", "Stopped: check your connection. … saved" (for a `NetworkFailure`),
      "Stopped: something went wrong. … saved", or "Not available in this build".
  - **Clear**:
    - It is tappable when something is downloaded and nothing is running.
    - It opens an `AlertDialog` with Cancel and Clear.
- **`shared/format_bytes.dart`** (new): `512 B`, `340 KB`, `1.2 MB`, in powers of
  1,000.
- **`app_en.arb`**: 15 strings (`settingsLyricsDownloaded…`, `settingsLyricsClear…`).

### Change From the Plan

- **The plan**: the status would be the Download all row's value.
- **What was built**: it is a line under the row.
- **Why**: a row's value is one line, and cut at half the row's width, so
  "Stopped: check your connection. 12 of 40 saved" didn't fit.

### Checked

- `flutter analyze` is clean, and `dart format` changes nothing.
- **App: 723 tests pass.**
- **One existing test changed**: the Settings screen test now expects 16 rows, not 13,
  and lists the three new ones.

### Notes

- **Stage 3** covers:
  - the DAO usage and clear
  - `download` and `clearCache`
  - the downloader: batches, Cancel, failure, re-run, and Clear refused while running
  - `formatBytes`
  - widget tests for the rows, the dialog, and leaving Settings mid-download
  - the emulator check
