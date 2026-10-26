---
stage: plan
bolt: 012-lyrics-engine-and-display-ui
created: 2026-10-26T17:27:28Z
---

## Implementation Plan: lyrics-engine-and-display-ui (bolt 4 of 9)

### Objective

The pure-Dart lyrics core in `zema_core` (stories 007 and 008): immutable lyrics models with JSON, expanding a song's singing order into the lines as sung, and the sync engine that finds the line being sung at a playback position. No UI; the LRC importer and sample songs (013) and the lyrics view (015) build on it.

### Deliverables

- `packages/zema_core/lib/src/lyrics/lyrics_models.dart`, immutable, with value equality and JSON round trip:
  - `LyricLine`: text, optional transliteration
  - `LyricSection`: id, kind (verse, chorus, bridge, other), lines
  - `Song`: id, title, optional transliteration, artist, album, sections, play order (section IDs; empty means the sections in written order)
  - `Recording`: id, song ID, optional artist, source (bundled, local file, YouTube, Telegram), optional duration, default offset
  - `SyncTiming`: recording ID, one start time per sung line
- `packages/zema_core/lib/src/lyrics/play_order.dart`:
  - `LineOccurrence`: index in the sung order, section ID and kind, line index, which repeat of the section it is, and the line itself
  - `expandPlayOrder(song)`: the occurrences in order. A chorus written once and listed three times gives its lines three times; empty sections add nothing; IDs that name no section are listed in the result (`missingSections`) and skipped
- `packages/zema_core/lib/src/lyrics/sync_engine.dart`:
  - `SyncEngine(starts)`: rejects start times that go backwards (`LyricsFormatFailure`)
  - `at(position, {offset})` → current occurrence (null before the first line) and next occurrence (null after the last). Pure function of the position, so a seek forwards or backwards needs no state.
  - `startOf(index, {offset})`: where to seek when a line is tapped
  - offset: positive means the lyrics come later (a line starting at 10 s with +0.5 s shows at 10.5 s)
  - `SyncedLyrics.of(song, timing)`: checks that the timing has one start per occurrence (`LyricsFormatFailure` otherwise)
- `LyricsFormatFailure` in `failures.dart`, for invalid JSON or timing.
- Exports and tests in `packages/zema_core/test/lyrics/`.

### Dependencies

- None new.

### Technical Approach

- Binary search over the start times: `at` is O(log n) and has no timers or state.
- `fromJson` validates types and required fields and throws `LyricsFormatFailure` with the field name, so bundled or (later) cloud data never crashes with a cast error.
- Equality via a small list-equality helper; no code generation.

### Acceptance Criteria

- [ ] Models are immutable, compare by value and survive a JSON round trip; malformed JSON gives `LyricsFormatFailure`
- [ ] A repeated chorus expands to repeated occurrences with a repeat count; bridge and empty sections; missing section IDs reported; no play order means written order
- [ ] Before the first line: no current line, first is next; after the last: last stays current, no next
- [ ] Correct at line boundaries ±0.3 s and with offsets of ±0.5 and ±1 s; seeks in both directions
- [ ] Timing that goes backwards, or doesn't match the number of occurrences, is rejected
- [ ] `dart analyze` and format clean; tests pass
