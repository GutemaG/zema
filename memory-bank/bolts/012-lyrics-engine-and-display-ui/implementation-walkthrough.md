---
stage: implement
bolt: 012-lyrics-engine-and-display-ui
created: 2026-10-26T17:30:44Z
---

## Implementation Walkthrough: lyrics-engine-and-display-ui (bolt 4 of 9)

### Summary

`zema_core` now has the lyrics model (song, sections, play order, recording, timing) with checked JSON, the expansion of a song into its lines as sung, and a stateless sync engine that finds the current and next line for a playback position and offset. Nothing in the app uses it yet.

### Structure Overview

Three files: models (data and JSON), play order (song → sung lines), and sync (sung lines + timing → current line). `SyncedLyrics` joins a song and one recording's timing and checks they fit, so the lyrics view (bolt 015) gets lines and an engine it can trust.

### Completed Work

- [x] `packages/zema_core/lib/src/lyrics/lyrics_models.dart` - `LyricLine`, `LyricSection` (`SectionKind`), `Song`, `Recording` (`RecordingSource`, default offset), `SyncTiming`; value equality; JSON read with type checks and written without empty optional fields
- [x] `packages/zema_core/lib/src/lyrics/play_order.dart` - `LineOccurrence` (index, section, line, repeat, `startsSection`), `PlayOrderExpansion` with `missingSections`, `expandPlayOrder`
- [x] `packages/zema_core/lib/src/lyrics/sync_engine.dart` - `SyncPosition`, `SyncEngine` (`at` by binary search, `startOf` for tap-to-seek, rejects backwards starts), `SyncedLyrics.of` (one start per sung line)
- [x] `packages/zema_core/lib/src/failures.dart` - `LyricsFormatFailure`
- [x] `packages/zema_core/lib/zema_core.dart` - exports

### Key Decisions

- **Durations in JSON as whole milliseconds** (`startsMs`, `durationMs`, `offsetMs`): exact, and the same in SQL later.
- **Offset sign**: positive means the lyrics come later, as a listener would describe "the words are early, move them later". `startOf` applies the same offset, so tapping a line lands where it is shown, never before 0.
- **Equal start times allowed**: two lines may start together (a quick pair); the later one is current. Only times going backwards are rejected.
- **No play order means written order**, so simple songs need no play order.

### Deviations from Plan

None.

### Dependencies Added

None.

### Developer Notes

- `expandPlayOrder` doesn't throw on unknown section IDs; it reports them, so a typo in data shows up in tests and logs rather than hiding a whole song.
