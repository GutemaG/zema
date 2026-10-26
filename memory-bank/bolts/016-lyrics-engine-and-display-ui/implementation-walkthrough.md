---
stage: implement
bolt: 016-lyrics-engine-and-display-ui
created: 2026-10-26T20:03:16Z
---

## Implementation Walkthrough: lyrics-engine-and-display-ui (bolt 8 of 9)

### Summary

- Songs can be found by a lyric line: Search has a Lyrics group and a Lyrics chip.
- A new Song detail page (S07) shows a song's full lyrics. It opens from those results or from **View lyrics** in the song menu.

### Files

- **`packages/zema_core/lib/src/lyrics/lyric_search.dart`**
  - **`LyricLineIndex`**:
    - one `SearchKey` per distinct line (text and transliteration)
    - `search` gives each song once, with its best line, best first and ties in song order
  - **`LyricMatch`**
  - **Tests**: 4, including a timed search over 5,000 lines.
- **`lib/features/lyrics/application/lyrics_links.dart`**
  - `songTracksProvider(songId)`: the library's tracks linked to a song
  - `songRecordingsProvider`
  - `lyricsSearchIndexProvider`: built once per song list
- **`lib/features/lyrics/presentation/song_detail_screen.dart`** (S07)
  - **Unknown or loading**:
    - An unknown or missing `id` shows `NotFoundScreen` (C07).
    - A spinner shows while the songs load.
  - **App bar**: A−/A+, shared with Now Playing's setting.
  - **Header**:
    - the title, transliteration and "artist · album"
    - Play, favorite and add to playlist for the first linked track
    - "Not on this phone" when no track is linked
  - **Lyrics tab**:
    - each section once, in play order
    - choruses with a label and a side rule
    - later repeats as "↻ Chorus" or "↻ Verse"
    - transliteration when on
  - **Info tab**: album, artist, and the recordings' sources ("Bundled sample").
- **Routes**:
  - `AppRoutes.song(id, base:)` → `<base>/song?id=…`, registered next to album and artist under **Library and Search**.
  - Home doesn't need it: the menu's View lyrics uses `detailBase` (Search when searching, otherwise Library).
- **Song menu**: **View lyrics** shows when the track is linked.
- **Search**:
  - `SearchScope.lyrics` chip, between Songs and Artists.
  - **Lyrics group** after Songs, with the top 4 and See all.
  - **`_LyricMatchRow`**: the song title and the matching line, with the words that match the query in bold. Tapping it opens the song in the Search tab.
- **ARB**: 12 new strings, including `lyricsRepeat` ("↻ {section}").
- **Tests**: the search chips test scrolls a chip into view, since there are now five.

### Emulator Check (release build)

- **Search**: typing "jaallatee" showed **Lyrics → Galatoomi**, with the line "Waaqayyo nu **jaallatee**".
- **Song detail**: tapping the result opened it, inside the Search tab, showing:
  - the title, "Zema Samples · Zema Samples", Play, favorite and add to playlist
  - the verse, the chorus block, the second verse and two "↻ Chorus" markers
