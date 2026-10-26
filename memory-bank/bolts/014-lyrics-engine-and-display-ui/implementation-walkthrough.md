---
stage: implement
bolt: 014-lyrics-engine-and-display-ui
created: 2026-10-26T17:49:24Z
---

## Implementation Walkthrough: lyrics-engine-and-display-ui (bolt 6 of 9)

### Summary

Songs on the phone now link to lyrics: automatically when a song's title matches (≥ 0.9, ties give no link), and by hand from the song menu (Match / Change / Unlink lyrics). Links are saved in a new `lyrics_links` table (schema v2); manual choices are never overwritten by automatic matching.

### Structure Overview

`SongMatcher` (core) decides which song a track is. A keep-alive provider in the app shell runs it over the library whenever the library or the lyrics change and replaces only the automatic links. `trackSongProvider` joins a track's link with the lyrics songs for the menu now and the lyrics view next.

### Completed Work

- [x] `packages/zema_core/lib/src/lyrics/track_matching.dart` - `SongMatcher` (song title or transliteration found in the track title, threshold 0.9, artist as tiebreak, ties → none), `autoLinkThreshold`
- [x] `apps/mobile/lib/app/database/tables.dart` - `LyricsLinks` (track ID key, song ID nullable, manual, linked time; deleted with its track)
- [x] `apps/mobile/lib/app/database/lyrics_links_dao.dart` - watch, set manual, replace automatic in one transaction
- [x] `apps/mobile/lib/app/database/zema_database.dart` - schema v2 with a step-by-step v1 → v2 migration (`zema_database.steps.dart` generated)
- [x] `apps/mobile/drift_schemas/zema/drift_schema_v2.json`, `test/app/database/zema/` - schema dump and generated migration tests (the old `test/app/database/generated` helpers moved here)
- [x] `apps/mobile/lib/features/lyrics/data/lyrics_links_repository.dart` - `LyricsLink`, `LyricsLinksRepository` (DatabaseFailure on errors)
- [x] `apps/mobile/lib/features/lyrics/application/lyrics_links.dart` - `lyricsSongsProvider`, `lyricsLinkSyncProvider`, `trackSongProvider`, `LyricsLinksController`
- [x] `apps/mobile/lib/features/lyrics/presentation/match_lyrics_sheet.dart` - searchable picker with the linked song checked
- [x] `apps/mobile/lib/features/library/presentation/song_menu.dart` - Match / Change lyrics, Unlink lyrics, snackbars
- [x] `apps/mobile/lib/app/app_shell.dart` - keeps the link sync alive
- [x] `apps/mobile/lib/l10n/app_en.arb` - 5 strings
- [x] `apps/mobile/test/features/library/presentation/song_menu_test.dart`, `test/app/database/schema_test.dart` - updated for the new items and schema v2

### Key Decisions

- **The song's title must be inside the track's title**, not the other way round, so noise around it in file titles doesn't matter, while a short track title can't match a long song.
- **Unlink is a manual "no lyrics" row**, so automatic matching doesn't bring the link back.
- **Matching in Dart, not SQL**: a handful of songs against the library, with keys built once per change.
- **Drift's step-by-step migrations** from `make-migrations`, so each future version adds one step and a generated test.

### Deviations from Plan

- 5 strings instead of about 8: the picker reuses the search hint and the "No matches" text.

### Dependencies Added

None.

### Developer Notes

- Emulator: the existing database upgraded to version 2 with its data. Exactly the three sample tracks (out of 1,000+) linked automatically: Galatoomi, ሰላም ለዚህ ቤት, ብርሃን ሆንልን. A linked track's menu shows Change and Unlink lyrics, and the picker lists the three songs with the linked one checked.
- The picker's search hint says "Search songs, artists, albums" (reused); acceptable for now, worth its own wording when the cloud catalog brings many songs.
- Full app suite passes after updating the song menu test.
