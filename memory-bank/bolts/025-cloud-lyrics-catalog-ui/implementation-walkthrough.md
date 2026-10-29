---
stage: implement
bolt: 025-cloud-lyrics-catalog-ui
created: 2026-10-29T11:38:13Z
---

## Implementation Walkthrough: cloud-lyrics-catalog-ui (bolt 4 of 7)

### Summary

- Search's Lyrics group now lists catalog songs:
  - found by **title** from the song index, so offline too
  - found by a **line** from the server, 300 ms after typing stops, so a song that
    was never downloaded is found
  - found by a line of a **downloaded** song, at once
- When the server can't be reached or fails, the group shows a C07 note with Try
  again.
- The phone's Songs, Artists and Albums groups are unchanged and never wait for the
  network.

### Files

- **`features/search/application/catalog_search.dart`** (new)
  - **`CatalogMatch`**: song ID, title, artist, score, and the matched line (null for
    a title match). It is built from a server hit or a downloaded song's
    `LyricMatch`.
  - **`CatalogTitleIndex`**: one `SearchKey` per index entry (title and
    transliteration), best first, then index order.
    - It is built once per index change by `catalogTitleIndexProvider`.
  - **`mergeCatalogMatches(titles, lines)`**: each song once, best first. The higher
    score wins; the title wins a tie, as on the server.
  - **`catalogLineSearchProvider(query)`**: auto-dispose family, with retry off.
    1. It waits `lineSearchDelay` (300 ms) on a `Timer` that is cancelled when the
       provider is disposed.
    2. It calls `CatalogRepository.search` and keeps only line hits.
    3. With no backend, or an empty query, it gives null.
    - Search watches only the current query, so typing on disposes the old
      provider. A query typed past is never sent, and a late answer for it is never
      shown.
- **`search_screen.dart`**
  - **The Lyrics group** is `mergeCatalogMatches` of:
    - the index title matches
    - the server's lines, once they arrive
    - the downloaded songs' lines
  - **New `_CatalogSearchNote`** shows above the rows when the server search failed:
    - "Offline: showing lyrics saved on this phone" (cloud icon) for a
      `NetworkFailure`
    - "Couldn't search the catalog" otherwise
    - Its Try again button invalidates the current query's provider.
    - The group shows with only the note when nothing matches, instead of the "No
      results" state.
  - **`_LyricMatchRow` became `_CatalogMatchRow`**: the line with matching words in
    bold, or the artist for a title match. It opens song detail by ID.
- **`app_en.arb`**: `searchCatalogOffline` and `searchCatalogFailed`.
- **`FakeCatalogRepository`**: `searchHits`, `searchCalls` and `searchGate`.

### Change From the Plan

- **The plan**: the server's lines would replace the downloaded songs' lines once
  they arrived.
- **What was built**: they are merged instead, each song once.
- **Why**: otherwise a line already on screen would disappear when the server
  answered without it. Songs removed from the catalog still drop out, because the
  downloaded lines come only from songs the index lists (bolt 024).

### Bugs Found While Implementing

- **Pending timer at test end**:
  - `Future.delayed` for the debounce left a timer running when a test ended.
    Flutter's test framework fails on that, and it would also keep a disposed
    provider's wait alive.
  - Fixed with a `Timer` cancelled in `ref.onDispose`.

### Checked

- `flutter analyze` is clean, and `dart format` changes nothing.
- **App: 704 tests pass.**
- **One existing test changed**: "the Lyrics chip shows only lyric matches".
  - Searching "galatoomi" now also matches the song's title in the index, and the
    title wins the tie with the chorus line.
  - So the row shows the artist instead of the line. The test now checks for one row
    with the artist.

### Notes

- **Stage 3**: tests for the debounce, stale answers, offline and error notes, Try
  again, a line from an uncached song, the title index and the merge. Then the
  emulator check, including the `umts` speed.
- **Translations**: the new strings fall back to English in am, om and ti, like the
  other strings added in this intent.
