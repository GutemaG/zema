---
stage: test
bolt: 026-cloud-lyrics-catalog-ui
created: 2026-10-29T12:52:12Z
---

## Test Walkthrough: cloud-lyrics-catalog-ui (bolt 5 of 7)

### Results

- **zema_core**: 201 tests pass.
- **zema_data**: 28 tests pass, against the local backend.
- **App**: 748 tests pass. That is 723 after implement, plus 25 new ones.
- `flutter analyze` is clean, `dart format` changes nothing, and
  `flutter build ios --simulator` builds.

### Tests Added

- **`cached_songs_dao_test.dart`** (1): usage counts songs and the bytes of their
  JSON, and follows saves and `clear`, which empties the cache.
- **`catalog_lyrics_repository_test.dart`** (6)
  - **`download`**:
    - it fetches an uncached song
    - it skips one cached at the index's version
    - it refetches an older copy
    - it throws on failure even with an older copy, which stays
    - it skips a song the index doesn't list
  - **`clearCache`**:
    - Drift and memory are emptied, and the index stays
    - the same repository then fails offline instead of serving its memory copy
- **`lyrics_download_test.dart`** (9), with 10 songs, so the batches are 4, 4 and 2:
  - it starts idle
  - it downloads every song, with progress (0/0, 0/10, 4/10, 8/10, 10/10), then
    finishes
  - a second run fetches no songs, and not the fresh index either
  - **start while running** returns at once and adds no new state, so progress isn't
    reset
  - Cancel stops after the batch in progress, which is kept (4 of 10)
  - **a failure** stops after its batch and keeps the 3 songs of that batch that
    finished (7 of 10), with the `NetworkFailure`
  - offline, the saved index is used (total 10)
  - **Clear**:
    - it removes the songs, and the index and a manual link stay
    - `songProvider` is read again, so offline the cleared song fails
  - Clear is refused while a download runs
- **`format_bytes_test.dart`** (1): B, KB and MB, and 999,500 B shows as 1.0 MB, not
  1000 KB.
- **`offline_lyrics_settings_test.dart`** (8):
  - nothing downloaded: "None yet", and Clear is off
  - **Download all**:
    - "0 of 3", the bar and Cancel show while it runs, and Download all and Clear are
      off
    - then "All lyrics downloaded" and "3 songs · … KB"
  - Cancel stops after the first batch ("Cancelled: 4 of 6 saved")
  - offline: "Stopped: check your connection"; another failure: "something went
    wrong"
  - **leaving Settings mid-download**: on return the progress and Cancel show; after
    it ends, "All lyrics downloaded"
  - **Clear**: the dialog's Cancel keeps the lyrics; Clear removes them, the index
    stays, and the rows reset
  - a build with no backend: "Not available in this build", and the row is off

### Bug Found by the Tests

- **The bug**: `formatBytes(999500)` gave "1000 KB".
- **Fix**: round to KB first, then switch to MB from 1,000 KB.

### Test Fix (Not an App Bug)

- **The problem**: the Settings widget tests timed out at first. While the index is
  checked, the progress bar has no value and animates without end, so
  `pumpAndSettle` never returned.
- **Fix**: while a download runs, the tests pump frames instead of settling.

### Planted Bugs

Each bug was planted alone, and the bolt's tests ran with a 2-minute watchdog. All 18
are caught:

- **On the first run, 16 of 18 were caught.** The two gaps:
  - **A second start while running restarted the download**: the old test only
    counted calls, and the restart shared the in-flight fetches. The test now checks
    that the second call returns at once and adds no state.
  - **The index fetched on every run**: the second-run test now checks the index
    calls.
- **Downloader**:
  - Cancel ignored: 2 failing
  - failure ignored: 5
  - a failure loses its batch: 6
  - open songs not re-read: 1
  - Clear while running: 1
  - one big batch: 4
- **Repository**:
  - download refetches everything: 2
  - download hides failures: 1
  - memory copy kept: 2
- **DAO**:
  - clear does nothing: 4
  - wrong byte count: 1
- **Settings**:
  - Clear on with nothing downloaded: 2
  - dialog Cancel still clears: 1
  - messages swapped: 2
  - no-backend row tappable: 1
- **`formatBytes`**: "1000 KB", 1 failing.

### Emulator Check

On Medium_Phone_API_37, over the bolt 025 build:

1. **Settings → Lyrics** showed "Downloaded lyrics: 2 songs · 2 KB", the songs opened
   in earlier checks.
2. **Download all**:
   - It finished at once with "All lyrics downloaded", and the storage became "3
     songs · 3 KB".
   - The log shows one `get_song`: the other two were already up to date.
   - With 3 songs the progress was too quick to see. The widget tests cover it.
3. **Backend stopped, app force-stopped and reopened**:
   - Searching "fiqir" showed the offline note and the line from ሰላም ለዚህ ቤት.
   - Opening it showed the lyrics.
4. **Clear**:
   - The dialog read "Clear downloaded lyrics? Songs will download again when you
     open them online. Your matched songs stay matched."
   - After Clear, the row read "None yet".
5. **Now Playing, Galatoomi**:
   - The panel said "Offline: these lyrics aren't downloaded yet".
   - So the track is still linked; an unlinked one would say "No lyrics".
6. The backend was started again.

### Notes

- **Storage is the JSON text length** (`length(document)` counts characters), so
  it's close to, not equal to, the bytes on disk.
- **A failing test can still hang a run**: one single-test run hung after its
  failure, the same issue as in earlier bolts.
