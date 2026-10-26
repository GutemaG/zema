---
stage: plan
bolt: 011-lyrics-engine-and-display-ui
created: 2026-10-26T15:00:36Z
---

## Implementation Plan: lyrics-engine-and-display-ui (bolt 3 of 9)

### Objective

Replace the Search tab's "Coming soon" with search over the phone's library (stories 005 and 006), using bolt 010's matching. The Lyrics chip and lyric results come in bolt 016.

### Deliverables

- **Search screen** (`features/search/presentation/search_screen.dart`), behind the shared `LibraryAccessGate`:
  - the existing search field; results update as you type; the keyboard closes when the list is dragged
  - scope chips All, Songs, Artists, Albums
  - **All**: the Songs, Artists and Albums groups, each with its top 4 results and "See all" (selects that chip); **one chip**: every result in that group
  - song rows: `TrackRow` with the song menu; a tap plays the song results as a queue from that song
  - artist rows (avatar, name, song count) and album rows (cover, album, artist) open their pages
  - no results: the C07 "No results" state
- **Empty field**: recent searches (newest first) with a remove button each and "Clear all"; with none, a hint ("Any keyboard works: kidist finds ቅድስት").
- **Recent searches** (`features/search/application/recent_searches.dart`): saved in shared preferences, kept across restarts. Up to 10, newest first. Duplicates by normalized form replace the old entry, and blank queries aren't saved. A query is saved when the keyboard's search key is pressed or a result is opened.
- **Matching** (`features/search/application/library_search.dart`):
  - a `SearchKey` per song (title), artist (name) and album (album and artist), built once per library change
  - `searchLibrary(index, query)` returns songs, artists and albums that match (`isMatch`)
  - order: score, then whether the normalized text contains the query (so "amlak" lists አምላክ before መላክ), then the library order
- **Album and artist pages from Search**: the same pages are also registered under `/search`, so the navigation bar stays on Search and Back returns to the results. `AppRoutes.album` and `AppRoutes.artist` get an optional base path.
- **Strings**: about 10 new; `searchComingSoonMessage` removed.

### Dependencies

- Bolt 010: `SearchKey`, `matchScore`, `isMatch`, `normalizeSearchText`.
- Intent 002 providers:
  - `libraryTracksProvider`, `albumsProvider`, `artistsProvider`: what to search
  - `playerControllerProvider`: playing a song result
  - `TrackRow`, `SongMenuButton`, `TrackArt`: the result rows
- `sharedPreferencesProvider`: recent searches.

### Technical Approach

- `searchIndexProvider` derives the keys from the library providers, so it rebuilds only when the library changes, not on every keystroke.
- The query lives in the screen's state; results are computed synchronously in `build` from the index (measured under 100 ms for 1,000 songs in a test).
- `RecentSearches` follows the existing sort controllers: a Notifier reading and writing shared preferences.
- Routes: a small helper builds the album and artist sub-routes, used under both `/library` and `/search`.

### Acceptance Criteria

- [ ] Typing shows grouped Songs, Artists, Albums using normalization and transliteration ("kidist" finds "ቅድስት")
- [ ] Scope chips filter; "See all" selects the chip
- [ ] A song result plays with the results as the queue; its menu is the song menu; artist and album results open their pages, and Back returns to Search
- [ ] No results shows C07; hidden songs aren't found
- [ ] Recent searches: saved on open or submit, newest first, max 10, no duplicates, no blanks; remove one; Clear all; kept after restart; hint when there are none
- [ ] Searching 1,000 songs takes < 100 ms per keystroke (test)
- [ ] 1.3× text in light and dark without overflow
- [ ] `flutter analyze` and format clean; existing tests pass (the Search "Coming soon" checks are updated)
- [ ] Checked on the Android emulator
