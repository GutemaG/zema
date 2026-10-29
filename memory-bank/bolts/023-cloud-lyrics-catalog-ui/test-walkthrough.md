---
stage: test
bolt: 023-cloud-lyrics-catalog-ui
created: 2026-10-29T10:40:00Z
---

## Test Walkthrough: cloud-lyrics-catalog-ui (bolt 2 of 7)

### Results

- **zema_core**: 201 tests pass.
- **zema_data**: 28 tests pass.
- **App**: 675 tests pass. That is 653 after implement, plus 22 new ones.
- `flutter analyze` is clean, `dart format` changes nothing, and
  `flutter build ios --simulator` builds (rebuilt after the fix below).

### Tests Added

- **`test/app/database/catalog_dao_test.dart`** (5):
  - the index starts empty
  - every field round-trips, ordered by ID, with UTC times
  - `replaceAll` removes, updates and adds in one go
  - an empty catalog empties the index
  - `watchEntries` emits after each replace
- **`test/features/catalog/application/catalog_index_test.dart`** (7), using a fixed
  `clock`:
  - a missing index is fetched, and the time is stored
  - under 6 h it is skipped; at 6 h it refreshes
  - `force` always refreshes
  - removed songs drop out, and versions update
  - a failure keeps the old index and time and rethrows, and the next call retries
  - with no backend nothing is fetched
  - overlapping calls share one fetch, and a later call fetches again
- **`lyrics_links_test.dart`**, group "The song index" (5):
  - the start-up refresh fills the index and tracks link
  - offline, tracks link from the saved index
  - first launch offline: no links, no error, and "Match lyrics" is offered
  - **a song removed from the catalog**:
    - the automatic link is deleted
    - the manual link row stays, but `trackSongProvider` gives null ("No lyrics")
    - other links are kept
  - the picker lists and searches index entries that aren't bundled
- **`search_screen_test.dart`**, group "Pull to refresh" (5):
  - a pull on recent searches forces a refresh, even though the index is fresh, and
    shows no message on success
  - a pull on the results also refreshes
  - a failure shows "Couldn't update the song list…" and keeps the index
  - a build with no backend shows "The song list isn't available in this build."
  - the list springs back to the top after a pull (the regression test for the bug
    below)
- **Test helpers**: `pumpZemaApp` and `lyricsOverrides` gained `backendConfigured`, so
  a test can run a build with no catalog.

### Planted Bugs

Each bug was planted alone, and the bolt's tests ran with a 2-minute watchdog. All 9
are caught:

- **Refresher**:
  - 6 h doubled: 1 failing test
  - `force` ignored: 9 failing
  - no call sharing: 1 failing
- **DAO**: no removal, 5 failing.
- **Linking**: no index check in `trackSongProvider`, 2 failing.
- **App shell**: no start-up refresh, 6 failing.
- **Search**:
  - pull not forced: 3 failing
  - no failure message: 1 failing
- **Picker**: lists nothing, 2 failing.

### Bug Found on the Emulator, and Fixed

- **What happened**: after a pull to refresh in Search, the recent-searches list stayed
  pushed down the screen instead of springing back.
- **Cause**: `copyWith(physics: const AlwaysScrollableScrollPhysics())` replaced the
  platform's scroll behaviour (clamping on Android) with plain physics, which doesn't
  pull an overscrolled list back.
- **Fix**: `AlwaysScrollableScrollPhysics(parent: <the platform physics>)`.
- **Test**: "the list springs back to the top after a pull" fails without the fix and
  passes with it.

### Emulator Check

On Medium_Phone_API_37, with `config/backend.local.json` from `tool/backend_env.sh`:

- **Online**:
  - The log shows `catalog.index: Song index refreshed: 3 songs`, so the emulator
    reached the backend at `10.0.2.2:54321`. This was the check deferred from bolt 022.
  - Galatoomi (sample audio from `tool/test_audio.sh --lyrics`) linked, and its synced
    lyrics showed in Now Playing.
- **With the backend stopped** (`npx supabase stop`):
  - The app restarted without fetching, because the index was under 6 h old.
  - Galatoomi's menu still offered View, Change and Unlink lyrics, so the links came
    from the saved index.
  - Pull to refresh showed "Couldn't update the song list. Check your connection.",
    and after the fix the list sprang back.
- The backend was started again afterwards.

### Notes

- **A failing widget test can leave a run hanging.** During the planted bugs, 5 of 9
  runs didn't finish after their failures and were killed by the watchdog. Passing
  runs finish normally (15 s for the whole app suite). Not investigated in this bolt;
  worth a look if it slows down debugging.
- **A quick swipe doesn't always count as a pull.** On the emulator, one fast swipe
  didn't trigger the refresh; a slower one did. This is Flutter's normal pull
  threshold, not a bug.
