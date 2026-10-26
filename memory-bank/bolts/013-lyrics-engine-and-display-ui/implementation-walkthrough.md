---
stage: implement
bolt: 013-lyrics-engine-and-display-ui
created: 2026-10-26T17:39:38Z
---

## Implementation Walkthrough: lyrics-engine-and-display-ui (bolt 5 of 9)

### Summary

`zema_core` reads LRC into a song, a recording and its timing, finding the chorus so it is written once, and defines the `LyricsRepository` interface. The app ships three placeholder songs in `assets/lyrics/`, read by a bundled repository, and the test-audio script can push matching audio with a pitch change at each line.

### Structure Overview

LRC text → `importLrc` (core) → song + recording + timing. The bundled repository reads an index of LRC files from the app's assets once, checks each song fits its timing, and serves list, get and search. The script reads the same LRC files to build the audio, so audio and timing can't drift apart.

### Completed Work

- [x] `packages/zema_core/lib/src/lyrics/lrc_import.dart` - `importLrc`, `LrcImport`, `LrcSkippedLine`: time tags in three forms, several per line, time order; ti/ar/al/offset tags; `[tr:]` transliteration; chorus detection; skipped lines reported
- [x] `packages/zema_core/lib/src/lyrics/lyrics_repository.dart` - `LyricsRepository` interface, `songSearchKey`, `searchSongs`
- [x] `apps/mobile/lib/features/lyrics/data/bundled_lyrics_repository.dart` - `BundledLyricsRepository` over an `AssetBundle`, `lyricsRepositoryProvider`
- [x] `apps/mobile/assets/lyrics/` - `index.json` and three LRC files: ብርሃን ሆንልን and ሰላም ለዚህ ቤት (Amharic, with transliteration), Galatoomi (Afaan Oromoo)
- [x] `apps/mobile/pubspec.yaml` - `assets/lyrics/` registered
- [x] `apps/mobile/tool/test_audio.sh` - `--lyrics` builds one file per sample song (title and artist tags, a new pitch at each line start) into `Music/Zema Lyrics`; `--clean` removes it too

### Key Decisions

- **Chorus = longest block of 2+ lines sung at least twice**, compared by text only (a repeat may lack the `[tr:]` line).
- **LRC offset sign converted**: LRC's positive offset shows lines earlier, Zema's later, so the importer negates it.
- **Title transliteration and length in `index.json`**: LRC has no standard tag for them.
- **The repository checks every song with `SyncedLyrics.of` at load**, so a song whose timing doesn't fit is skipped rather than failing later in the lyrics view.

### Deviations from Plan

- **No bridge in the samples**: LRC has no way to mark sections, so the importer only finds verses and a chorus. A bridge needs section marks, which come with the sync editor (intent 006) or richer data (004). All three samples have a chorus sung three times.

### Dependencies Added

None.

### Developer Notes

- Check: the three songs import as v1, chorus, v2, chorus, chorus with 10–11 timed lines each, no skipped lines, and pass `SyncedLyrics.of`.
- `tool/test_audio.sh --lyrics` generated 53 s and 43 s files tagged "ብርሃን ሆንልን" etc. and pushed them to the emulator.
- **The sample text is placeholder Amharic and Afaan Oromoo written for testing; it needs a native speaker's review before any release.**
