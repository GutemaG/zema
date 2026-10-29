---
stage: test
bolt: 025-cloud-lyrics-catalog-ui
created: 2026-10-29T11:59:59Z
---

## Test Walkthrough: cloud-lyrics-catalog-ui (bolt 4 of 7)

### Results

- **zema_core**: 201 tests pass.
- **zema_data**: 28 tests pass, against the local backend.
- **App**: 723 tests pass. That is 704 after implement, plus 19 new ones.
- `flutter analyze` is clean, `dart format` changes nothing, and
  `flutter build ios --simulator` builds.

### Tests Added

- **`test/features/search/application/catalog_search_test.dart`** (10)
  - **`CatalogTitleIndex`**:
    - Latin letters find an Ethiopic title
    - the transliteration is searched, including a word found only there
    - equal scores keep index order
    - an empty query or no match finds nothing
  - **`mergeCatalogMatches`**:
    - each song once, best first
    - a better line beats the title, and the title wins a tie
    - equal scores keep the order they came in
  - **`catalogLineSearchProvider`**:
    - it keeps only line hits, after at least 300 ms
    - with no backend or an empty query, it gives null and sends nothing
    - a failure is thrown and not retried
- **`test/features/search/presentation/catalog_results_test.dart`** (9)
  - **Phone results and catalog titles show on the first frame**: no request goes out
    at 299 ms, one at 300 ms.
  - **Online, a line from a song never downloaded is found**: tapping it opens song
    detail in the Search tab and downloads the song.
  - **Typing on sends only the last query.**
  - **A late answer for an earlier query is never shown**: it is held, released after
    the next query, and dropped.
  - **Offline**:
    - downloaded lines show before the server is asked
    - then the offline note shows above them, with Try again
    - phone results and catalog titles are unaffected
  - **Offline with nothing found**: the note shows instead of "No results".
  - **A server error** shows its own note. Try again asks again and shows the lines.
  - **A build with no backend** shows no note, and phone results still work.
  - **The Lyrics chip** shows catalog titles and lines without phone songs.
- **Changed in implement**: `song_detail_test` "the Lyrics chip shows only lyric
  matches" (see the implementation walkthrough).

### Planted Bugs

Each bug was planted alone, and the Search and song detail tests ran with a 2-minute
watchdog. All 13 are caught:

- **Provider**:
  - no debounce: 2 failing (the run then hung)
  - the old query still sent: 7
  - title hits kept: 1
  - automatic retry: 1
- **Merge**: a line wins a tie, 2 failing.
- **Title index**: transliteration not indexed, 1 failing.
  - On the first run **no test caught this**. "lezih" also finds "ለዚህ" directly,
    because Search matches Latin letters to Ethiopic.
  - A test with a word found only in the transliteration was added, and it catches
    the bug.
- **Screen**:
  - no index titles: 2 (the run then hung)
  - server lines ignored: 3
  - downloaded lines replaced: 3
  - no note: 3
  - notes swapped: 3
  - Try again does nothing: 1
  - "No results" hides the note: 2

### Emulator Check

On Medium_Phone_API_37, with the network set to `umts` speed and delay:

1. **Online**:
   - "bechelema" found "በጨለማ መንገድ ምራን" from ብርሃን ሆንልን, which was never
     downloaded, with the typed word in bold.
   - Tapping the line opened song detail, which downloaded the song (`get_song`).
2. **Backend stopped**:
   - "galatoomi" showed the phone track under Songs, and the offline note with Try
     again.
   - The catalog title showed under Lyrics.
   - "bechelema", downloaded in step 1, showed its line under the note.
   - "fiqir", from a song not downloaded, showed only the note.
3. **Backend started, Try again tapped**: "ፍቅር በመካከላችን" from ሰላም ለዚህ ቤት showed.
4. The backend is running again, and the network is back to full speed.

### Timing (< 1 s on 3G)

- **What the log shows**: the new `search.catalog` log line records each request's
  time.
  - Warm requests took 17–25 ms.
  - The first request after the backend restarted took 594 ms.
- **Not proven on 3G**: the emulator's `umts` setting doesn't seem to slow traffic to
  the host (10.0.2.2), so these times are close to local speed.
- **Why it should still hold**:
  - An answer is a few hundred bytes, so on 3G the time is about one round trip plus
    the server's time.
  - The server's time is 2–100 ms for these queries.
  - Bolt 020's benchmark measured `search_songs` on 5,000 songs at 16–210 ms, and
    about 315 ms for a one-letter query.
- **Still to do**: a measurement over a real or properly throttled slow network,
  before release.

### Notes

- **A failing test can still hang a run**: 2 of the 13 planted-bug runs hung after
  their failures, the same issue as in bolts 023 and 024.
- **On the emulator**, typing "bechelema" with `adb input text` sent two searches,
  about a second apart. This is probably because `adb` types slowly enough for part
  of the word to pass the 300 ms wait; it wasn't looked into.
