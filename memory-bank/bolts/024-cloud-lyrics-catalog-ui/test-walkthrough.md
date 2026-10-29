---
stage: test
bolt: 024-cloud-lyrics-catalog-ui
created: 2026-10-29T11:20:00Z
---

## Test Walkthrough: cloud-lyrics-catalog-ui (bolt 3 of 7)

### Results

- **zema_core**: 201 tests pass.
- **zema_data**: 28 tests pass, against the local backend.
- **App**: 704 tests pass. That is 679 after implement, plus 25 new ones.
- `flutter analyze` is clean, `dart format` changes nothing, and
  `flutter build ios --simulator` builds.

### Tests Added

- **`test/app/database/cached_songs_dao_test.dart`** (5):
  - the cache starts empty
  - a song reads back whole, with its version and time
  - saving again replaces the old copy
  - `watchSongs` lists songs by ID and emits after a save
  - a row that no longer decodes counts as not cached
- **`test/features/catalog/data/catalog_lyrics_repository_test.dart`** (13):
  - a song the index doesn't list is null, and nothing is fetched
  - the first read fetches and saves; later reads, even by a new repository while
    offline, use the cache
  - a newer index version is fetched on next use, by a new repository and by the
    same one
  - offline, an older cached copy is shown and kept
  - offline and never cached:
    - a `NetworkFailure` is thrown and **nothing is cached**
    - the next call tries again
  - other failures are thrown too, and nothing is cached
  - a song the server no longer has is null, and nothing is cached
  - with no backend, an uncached song is a `NetworkFailure`
  - reads at the same time share one fetch; later ones fetch again
  - **a cached song reads in under 300 ms** (timed)
  - recordings and timing come from the cache only
  - `songs`/`search` list only cached songs that the index still lists
- **`lyrics_view_test.dart`** (4):
  - **offline and never downloaded**: shows the C07 offline state.
    - Try again while still offline asks again.
    - Try again once online shows the lyrics.
  - another failure shows the C07 error state
  - lyrics downloaded once still show offline, with no fetch
  - offline, the panel under the artwork says why, and tapping it opens Try again
- **`song_detail_test.dart`** (2):
  - opening a song downloads its lyrics
  - **offline and never downloaded**:
    - shows C07 with a back button, not "not found"
    - Try again shows the song
- **`lyrics_links_test.dart`** (1): a new index version downloads the song again; a
  refresh with the same versions downloads nothing.

### Bug Found by the Tests, and Fixed

- **Cause**: `trackLyricsProvider` used Riverpod 3's default automatic retry. When
  the download failed, it kept retrying in the background and stayed "loading", so
  Now Playing showed nothing instead of C07.
- **Fix**: retry is off, as on `songProvider`. "Try again" is the retry.

### Bug Found on the Emulator, and Fixed

- **What happened**: offline, the small panel under the artwork said "No lyrics for
  this song". That was wrong: the song has lyrics, they just aren't downloaded yet.
- **Fix**: it now says "Offline: these lyrics aren't downloaded yet", or "Couldn't
  load the lyrics" for other errors. Tapping it opens the lyrics view with Try again.
- **Test**: "offline, the panel under the artwork says why".

### Planted Bugs

Each bug was planted alone, and the bolt's tests ran with a 2-minute watchdog. 14 of
15 are caught:

- **Repository**:
  - version ignored: 4 failing
  - no old-copy fallback: 6
  - offline treated as missing: 6
  - no shared fetch: 1
  - removed songs still listed: 1
  - nothing saved: 6
- **DAO**: a bad row throws, 1 failing.
- **Providers**:
  - index read instead of watched: 2 (the run then hung; see Notes)
  - automatic retry back: 2
- **UI**:
  - no C07 in Now Playing: 2
  - Try again does nothing: 2
  - offline and error swapped: 3
  - song detail shows no C07: 4
- **Not caught: `songProvider` without its own index check.** No test can catch it,
  because `CatalogLyricsRepository.song` makes the same check, so the behaviour is
  identical. The provider's check only saves a database read.

### Emulator Check

On Medium_Phone_API_37, installed over the bolt 023 build, so this is a real v3→v4
upgrade:

1. **Backend stopped**:
   - The app upgraded and started normally.
   - Search for "Galatoomi" showed no Lyrics group (nothing downloaded).
   - In Now Playing, the panel said it was offline.
   - The lyrics view showed "You're offline" with Try again.
2. **Backend started**: Try again downloaded the lyrics, which showed in sync.
3. **Backend stopped, app force-stopped and reopened** (nothing in memory):
   - Galatoomi's lyrics showed from Drift.
   - Searching "jaallatee" found the line.
   - Song detail opened.
4. The backend was started again afterwards.

### Notes

- **A failing test can still hang a run.** One of the 15 planted-bug runs hung after
  its failures, which is the issue noted in bolt 023. The watchdog handles it.
- **Song detail shows "Zema Samples · Zema Samples"**, because the fixture's artist and
  album are both "Zema Samples". It isn't new and isn't a bug.
- **Google sign-in prompt**: during the check, the emulator showed a Google Play
  services sign-in prompt over the app. It's unrelated to Zema.
