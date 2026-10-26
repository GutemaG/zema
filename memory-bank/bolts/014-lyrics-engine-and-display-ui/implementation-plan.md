---
stage: plan
bolt: 014-lyrics-engine-and-display-ui
created: 2026-10-26T17:44:15Z
---

## Implementation Plan: lyrics-engine-and-display-ui (bolt 6 of 9)

### Objective

Link the phone's songs to lyrics (story 011): automatically by title, and by hand from the song menu ("Match lyrics" / "Unlink lyrics"), saved in the database so links survive restarts and rescans. The lyrics view (015) shows the linked song's lyrics.

### Deliverables

- `packages/zema_core/lib/src/lyrics/track_matching.dart`: `matchTrackToSong(track, songs)`:
  - compares the song's title (and transliteration) with the track's title, using bolt 010's normalization and matching. A track title with extra noise ("Selam - Official Video") still matches; the song's words must all be in the track's title.
  - links only at a score of 0.9 or more
  - the artist breaks ties between equal titles; if two songs are still equal, no link (better none than a wrong one)
- **Database schema v2**: a `lyrics_links` table, deleted with its track:
  - track ID, song ID (empty for a manual "no lyrics"), manual or automatic, linked time
  - v1 → v2 migration with a saved schema dump and generated migration test
- `LyricsLinksDao`:
  - watch all links
  - set a manual link, or a manual "no lyrics" (Unlink)
  - replace the automatic links in one transaction, leaving manual ones alone
- `features/lyrics/application/lyrics_links.dart`:
  - `lyricsLinkSyncProvider` (kept alive by the app shell like play history): whenever the library or the lyrics change, matches every track without a manual link and saves the automatic links
  - `trackSongProvider(trackId)`: the linked song, or null; a link to a song that no longer exists counts as none
  - `LyricsLinksController`: `link`, `unlink`
- **Song menu**: "Match lyrics" (or "Change lyrics" when linked) opens a picker sheet with a search field and the lyrics songs (title, transliteration, artist). Picking one links it manually, with a snackbar; "Unlink lyrics" shows when linked.
- **Strings**: about 8 new.

### Dependencies

- Bolt 013: `LyricsRepository`, `lyricsRepositoryProvider`, `searchSongs`; bolt 010: matching.
- Drift migrations (`drift_dev make-migrations`, already configured in `build.yaml`).
- Intent 002: song menu, `libraryTracksProvider`, app shell keep-alives.

### Technical Approach

- Matching runs in the sync provider, not in the database: all tracks against a handful of songs is quick (one SearchKey per song, built once).
- Only the automatic rows are replaced on each run; a manual link or Unlink always wins, survives rescans (rows are keyed by Zema's track ID), and goes when the track's row is deleted.
- `trackSongProvider` joins links with the repository's songs in memory.

### Acceptance Criteria

- [ ] A track whose title matches a song (≥ 0.9) links automatically; noise in the title doesn't stop it; two equal candidates give no link
- [ ] Match lyrics links by hand; Unlink stops automatic linking for that track; both survive a rescan and a restart
- [ ] A rerun of automatic matching never overwrites a manual choice
- [ ] Schema v2 with a v1 → v2 migration test; existing data is kept
- [ ] The picker searches the lyrics; 1.3× and both themes fit
- [ ] Emulator: the three sample tracks link automatically
- [ ] Analyze and format clean; tests pass
