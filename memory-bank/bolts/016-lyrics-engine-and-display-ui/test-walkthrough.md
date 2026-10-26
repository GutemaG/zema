---
stage: test
bolt: 016-lyrics-engine-and-display-ui
created: 2026-10-26T20:29:47Z
---

## Test Report: lyrics-engine-and-display-ui (bolt 8 of 9)

### Summary

- **Tests**: 818/818 passed:
  - 178 in `packages/zema_core`, up from 174
  - 640 in `apps/mobile`, up from 626
- **Coverage**:
  - `search_screen.dart`: 189/191
  - `song_menu.dart`: 115/116
  - `lyrics_links.dart`: 42/46
  - `song_detail_screen.dart`: 137/151. Not covered: the loading spinner, add to playlist, the sources other than bundled, and transliteration lines when on (the same code is tested on Now Playing).
  - App total: 92.5%
- **CI sequence run locally**: format check, `dart analyze`, `dart test`, `flutter analyze` and `flutter test` all exit 0. The iOS simulator build compiles.
- **Planted bugs**: 4 caught:
  - a song listed once per matching line
  - repeat markers drawn as full sections
  - Play shown for a song with no track on the phone
  - the Lyrics chip still showing track matches
- **Gap closed**: the first version of the "once per song" planted bug survived, because no test song had two different matching lines. The test now has one.

### Test Files

- [x] `packages/zema_core/test/lyrics/lyric_search_test.dart`: 4 tests
  - matches in either script, with the best line returned
  - each song once, best first
  - empty and unrelated queries
  - a search over 5,000 lines takes under 100 ms
- [x] `apps/mobile/test/features/lyrics/presentation/song_detail_test.dart`: 14 widget tests
  - **Lyric search**:
    - The Lyrics group shows the matching line, with the matching word in bold and the rest plain.
    - A chorus sung three times appears once.
    - The Lyrics chip shows only lyric matches.
    - A result opens `/search/song?id=galatoomi`.
  - **Song detail**:
    - The header shows "artist · album" and Play.
    - Lyrics show the chorus once and two "↻ Chorus" markers.
    - Play plays the linked track, and favorite toggles it.
    - With no track on the phone, Play and favorite are hidden and "Not on this phone" shows.
    - A+ ×2 makes the text 1.2× larger, and the title's transliteration shows.
    - The Info tab shows album and source.
    - An unknown or missing ID shows "not found".
    - View lyrics shows only for linked tracks and opens the page.
    - 1.3× text at the largest lyric size, in light and dark: no overflow.
- [x] `search_screen_test.dart`: updated to scroll the five chips into view.

### Acceptance Criteria

**Story 014: Song detail**
- ✅ Opens from View lyrics and from lyric results, with the title, transliteration, artist and album, plus Play, favorite and add to playlist (tests and emulator)
- ✅ The Lyrics tab shows sections, chorus blocks, ↻ markers and A−/A+ (tests and emulator)
- ✅ The Info tab shows album, artist and source (test)
- ✅ A malformed link shows C07 (test)
- ✅ No linked track hides Play (test)

**Story 015: lyric search**
- ✅ The Lyrics group shows the matching line, each song once (tests and emulator)
- ✅ The Lyrics chip shows only lyric matches (test)
- ✅ A result opens Song detail (test and emulator)
- ✅ Under 100 ms over 5,000 lines (test)
