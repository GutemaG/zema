---
stage: plan
bolt: 013-lyrics-engine-and-display-ui
created: 2026-10-26T17:36:12Z
---

## Implementation Plan: lyrics-engine-and-display-ui (bolt 5 of 9)

### Objective

Read timed lyrics written as LRC into bolt 012's models (story 009), and ship a few placeholder songs in the app behind a `LyricsRepository`, with matching test audio for the device (story 010). Still no lyrics UI; linking (014) and the lyrics view (015) use this.

### Deliverables

- `packages/zema_core/lib/src/lyrics/lrc_import.dart`: `importLrc(text, songId:, recordingId:)` → song, recording, timing and the lines it skipped.
  - time tags `[mm:ss]`, `[mm:ss.xx]`, `[mm:ss.xxx]`; several tags on one line give that line at each time; lines are put in time order
  - `[ti:]`, `[ar:]`, `[al:]` set title, artist and album; `[offset:±ms]` sets the recording's offset (LRC's sign: positive shows lines earlier, so it is negated into Zema's)
  - `[tr:…]` right after a timed line gives that line's transliteration (a Zema extension; other players ignore unknown tags)
  - **chorus detection**: the longest block of two or more lines that is sung at least twice becomes one chorus section, and the lines between its repeats become verses (v1, v2 …); without a repeated block the song is one verse
  - lines with neither a time nor a known tag, and timed lines with no text, are skipped and listed with their line numbers; Ethiopic text is kept exactly
  - no timed lines at all: `LyricsFormatFailure`
- `packages/zema_core/lib/src/lyrics/lyrics_repository.dart`: `LyricsRepository` interface:
  - `songs()`, `song(id)`, `recordings(songId)`, `timing(recordingId)`
  - `search(query)`, matching title, transliteration and artist with bolt 010's `isMatch`
- `apps/mobile/lib/features/lyrics/data/bundled_lyrics_repository.dart`: loads `assets/lyrics/index.json` and the LRC files it lists, once, on first use. A malformed or duplicate entry is skipped and logged at FINE, and the rest load. `lyricsRepositoryProvider` exposes it.
- `apps/mobile/assets/lyrics/`: 3 placeholder songs written for Zema, marked as samples:
  - two in Amharic, one in Afaan Oromoo
  - each with a repeated chorus, one also with a bridge
  - timed with LRC, with transliteration lines
  - `index.json` holds each song's ID, file, title transliteration and length
  - the text needs a native speaker's review before any release
- `apps/mobile/tool/test_audio.sh --lyrics`: generates one audio file per sample song, tagged with its title and artist, and pushes them to `Music/Zema Lyrics`. The tone changes pitch at every line start, so a change of pitch marks exactly when the highlight should move.

### Dependencies

- Bolt 012: models, `expandPlayOrder`, `SyncedLyrics`, `LyricsFormatFailure`.
- Bolt 010: `SearchKey`, `isMatch` for repository search.
- Flutter's asset bundle (`rootBundle`) for the bundled files; `ffmpeg` and `adb` for the script (already used by it).

### Technical Approach

- Chorus detection looks at the line texts in sung order and tries block lengths from long to short, so a two-line chorus wins over its single lines. Songs are a few dozen lines, so the simple search is instant.
- The bundled repository takes an `AssetBundle`, so tests feed it files without Flutter assets.
- The importer's output always passes `SyncedLyrics.of` (one start per sung line), which the tests check for every sample song.

### Acceptance Criteria

- [ ] Time tags in all three forms; several tags on a line; out-of-order lines sorted
- [ ] Metadata and offset tags applied; `[tr:]` attaches transliteration
- [ ] A repeated block becomes one chorus in the play order; verses between; no repeat → one verse
- [ ] Malformed and empty lines skipped and reported; Ethiopic kept; nothing timed → failure
- [ ] The repository lists, gets and searches the 3 bundled songs; every one passes `SyncedLyrics.of`
- [ ] Malformed or duplicate bundled entries are skipped and the rest load
- [ ] The script makes and pushes the sample audio, with a pitch change at each line
- [ ] `dart analyze`, `flutter analyze` and format clean; tests pass
