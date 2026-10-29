---
stage: plan
bolt: 025-cloud-lyrics-catalog-ui
created: 2026-10-29T11:24:42Z
---

## Implementation Plan: cloud-lyrics-catalog-ui (bolt 4 of 7)

### Objective

Search finds catalog songs, not only what is on the phone (story 004, FR-11):

- Catalog songs found by **title** come from the song index in Drift, so they are
  found offline too.
- Catalog songs found by a **lyric line** come from the server's `search_songs` when
  online, so a line from a song that was never downloaded is found.
- Offline, or when the server fails, the Lyrics group shows a C07 note with Retry and
  falls back to lines of downloaded songs.
- Phone results (Songs, Artists, Albums) never wait for the network.

### Deliverables

- **Catalog title search** (`features/search/application/catalog_search.dart`, new)
  - **`CatalogTitleIndex`**: a `SearchKey` per index entry (title and
    transliteration), built once per index change. It is ranked like
    `LibrarySearchIndex`.
  - **`catalogTitleIndexProvider`**, built from `catalogEntriesProvider`.
- **Server line search**
  - **`catalogLineSearchProvider(query)`**: an auto-dispose `FutureProvider.family`,
    with retry off.
    1. It waits **300 ms**. If the query changed in the meantime, the provider has
       been disposed and nothing is sent.
    2. It calls `CatalogRepository.search(query)` and keeps the hits that matched a
       line (`line != null`). Title hits are already covered by the index.
    3. **Stale responses are dropped**: each query is its own provider, and Search
       only watches the current one, so a slow answer for an old query is never
       shown.
    4. With no backend in the build, it returns nothing, and no note is shown.
- **Merged Lyrics group**
  - **One row type, `CatalogMatch`**: song ID, title, artist, the matched line (or
    null for a title match), and score.
  - **Rows**, one per song, best first:
    - title matches from the index
    - line matches from the server when its answer has arrived
    - before the answer arrives, or if the search fails, line matches from downloaded
      songs (today's `lyricsSearchIndexProvider`)
  - **When a song matches both ways**, the higher score wins, and the title wins a
    tie, as on the server.
  - **Row**: the lyrics icon and the title. The subtitle is the line, with the
    matching words in bold, or the artist for a title match. Tapping a row opens song
    detail (S07), which downloads the song if needed (bolt 024).
  - **The group keeps its place and chips**: All shows 4 rows with "See all", and the
    Lyrics chip shows them all.
- **C07 note in the Lyrics group**
  - **Offline** (`NetworkFailure`): "Offline: showing lyrics saved on this phone",
    with Retry.
  - **Other failures**: "Couldn't search the catalog", with Retry.
  - **Retry** invalidates `catalogLineSearchProvider` for the current query.
  - The note shows even when nothing local matches, so an empty offline search
    explains itself.
  - **New strings**: `searchCatalogOffline`, `searchCatalogFailed`. The button
    reuses `actionTryAgain`.
- **Test fake**: `FakeCatalogRepository.search` returns given `searchHits`, records
  `searchCalls`, and can be held with a gate, to test the 300 ms debounce and stale
  answers.

### Dependencies

- Bolt 023: the index (`catalogEntriesProvider`).
- Bolt 024: song detail downloads an uncached song.
- Backend story 005: `search_songs`, already wrapped by
  `SupabaseCatalogRepository.search`.

### Technical Approach

- **Debounce without timers in the widget**: the delay is inside the provider. Each
  keystroke watches a new family key, so Riverpod disposes the old one, which cancels
  its request before it's sent.
- **Local first**: the Songs, Artists and Albums groups and the index title matches
  are computed synchronously, as today. Only line matches have a network source.
- **No new tables**: search results aren't cached. History sync is out of scope.

### Acceptance Criteria → Tests

| Criterion | Test |
|-----------|------|
| Phone results at once; catalog title matches from the index | widget test: phone groups and an index-only song show on the first frame, before any server call |
| Online, line matches from the server after 300 ms; an uncached song's line is found | widget test: no call before 300 ms, then one; the uncached song's line shows; typing on drops the first query |
| Stale responses dropped | widget test: a held answer for "a" is released after "ab"; only the results for "ab" show |
| Offline: C07 note plus cached lines; phone results unaffected | widget test with a `NetworkFailure` |
| Server error: note with Retry | widget test: Retry asks again and then shows the server lines |
| < 1 s on a 3G-class network | emulator check, with the network speed set to `umts` |

### Emulator Check

1. **Online, nothing downloaded** (data cleared): search a line from Galatoomi. It's
   found, and tapping it opens song detail, which downloads the song.
2. **Network speed `umts`**: time a catalog search from the log. Expected: under 1 s.
3. **Backend stopped**: the note shows, with the downloaded lines below it. Songs and
   Artists still show.
4. **Backend started, Retry tapped**: the server lines show.
