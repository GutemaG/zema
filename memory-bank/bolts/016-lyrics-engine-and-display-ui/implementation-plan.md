---
stage: plan
bolt: 016-lyrics-engine-and-display-ui
created: 2026-10-26T19:59:00Z
---

## Implementation Plan: lyrics-engine-and-display-ui (bolt 8 of 9)

### Objective

Add a Song detail page (S07) that shows a song's full lyrics without playing it (story 014). Let Search find songs by a lyric line someone remembers (story 015).

### Deliverables

- **Route**: `/song/:id`
  - Registered under Library, Search and Home, the same way as album and artist (`AppRoutes.song(base, id)` + `detailBase`), so the tab bar stays.
  - An unknown ID shows the existing `NotFoundScreen` (C07).
- **`features/lyrics/presentation/song_detail_screen.dart`** (S07)
  - **Header**:
    - the title and transliteration
    - the artist and album
    - **Play**, favorite and add to playlist
  - **Linked tracks**:
    - The three actions apply to the first local track linked to the song.
    - With no linked track, they are hidden and a line says "Not on this phone".
  - **Two tabs**:
    - **Lyrics**:
      - each section in play order, written once, with a "Chorus" label
      - a chorus repeat shows as a short "↻ Chorus" marker rather than all its lines again
      - transliteration under each line when the setting is on
      - A−/A+ in the app bar, shared with Now Playing's setting
    - **Info**: album, artist, and source ("Bundled sample" for now).
- **Ways in**:
  - **View lyrics** in the song menu when the track is linked, alongside Change and Unlink lyrics.
  - a lyric search result
- **`zema_core`**: `LyricLineIndex`
  - built once from the songs, with one `SearchKey` per distinct line (title, line and transliteration)
  - `search(query)` gives each song at most once, with its best-matching line, best first
- **Search**:
  - **Lyrics group**: added to Search results, after Songs. Each row shows the song title and the matching line, with the query words in bold.
  - **Lyrics chip**: shows only lyric matches.
  - Tapping a result opens Song detail.
  - The lyric index is built once per song list (`lyricsSearchIndexProvider`), so each keystroke only scores keys.
- **Strings**: about 10 new.

### Dependencies

- Bolt 013: `LyricsRepository`, `lyricsSongsProvider`; bolt 010: `SearchKey` and `matchScore`.
- Bolt 014: links, to find the songs' local tracks. Bolt 015: `lyricsDisplayProvider` and the line styling.
- Bolt 011: Search screen, scope chips and `detailBase`.

### Technical Approach

- **Repeat markers**: `playOrder` is walked. Each section is drawn the first time it appears, and each later appearance becomes a marker row.
- **Local tracks**: a `linkedTracksProvider(songId)` joins the links with `libraryTracksProvider`.
- **Search timing**: the sample has about 30 lines, and real catalogs will have thousands. Scoring precomputed keys is about the same work as the track index, so the < 100 ms target holds. A unit test times a search over 5,000 lines.

### Acceptance Criteria

- [ ] Song detail opens from View lyrics and from lyric results. It shows the title, transliteration, artist and album, plus Play, favorite and add to playlist, which are hidden when no track is linked.
- [ ] The Lyrics tab shows sections, chorus blocks, ↻ repeat markers and A−/A+.
- [ ] The Info tab shows the album, artist and source.
- [ ] An unknown song ID shows "not found".
- [ ] Lyric search shows a Lyrics group with the matching line, each song once. The Lyrics chip filters to lyric matches, and tapping a result opens Song detail.
- [ ] Search stays under 100 ms over 5,000 lines.
- [ ] 1.3× text in light and dark: no overflow.
- [ ] Emulator: searching "jaallatee" finds Galatoomi and opens its detail page.
- [ ] Analyze and format clean; tests pass.
