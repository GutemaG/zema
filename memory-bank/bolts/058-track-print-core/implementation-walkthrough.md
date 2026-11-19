---
stage: implement
bolt: 058-track-print-core
created: 2026-11-19T18:30:00Z
---

## Implementation Walkthrough: tag clean-up

### Files

- `packages/zema_core/lib/src/lyrics/track_tags.dart` (new, exported):
  - `cleanTag` and `cleanFileName` clean up text.
  - `isJunkTag` detects empty or placeholder tags.
  - `matchTitle` uses the title tag, or the file name when the tag is junk.
  - `matchArtist` uses the artist tag, or null for a channel, junk or the title again.
  - `artistHints` joins the title and the file name.
- `packages/zema_core/lib/src/lyrics/track_matching.dart`: `SongMatcher.match` matches
  `matchTitle`. The artist tie-break takes the best of the `matchArtist` score and the
  song's artist found in `artistHints`.

### Decisions

- **The known artist isn't cut out of the title.** Containment already ignores extra
  words, so finding the artist is enough to break the tie.
- **The file name also feeds the tie-break.** `Kuku- Tizita.mp3` has the title tag
  "Tizita" and the artist tag "The Best Of Amharic I". Only its name says Kuku, and
  three other songs are called Tizita or Tizta.
- **Leading track numbers are stripped from file names only,** so title tags like
  "7 Days" are kept.
- **The length tie-break is deferred to bolt 060.** The song index has no lengths.

### Result on the owner's 98 files

The catalog was built from the files' real titles; the script is in the scratchpad.

| Old → new | Files |
|---|---|
| Right → right | 67 |
| Missed → right | 14 (8 "Track 0N" tags, 6 equal-title ties) |
| No song, nothing linked → same | 17 ("Track NN" only, left for the track print) |
| Worse | 0 |
