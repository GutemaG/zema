---
stage: plan
bolt: 058-track-print-core
created: 2026-11-19T18:00:00Z
---

## Implementation Plan: tag clean-up (story 001)

### What the owner's files show

98 files (`~/Documents/musics`, `~/Documents/Files`):

- **Fixable (8):** `Tilahun old/01 Endene Filagot.MP3` has the title tag `Track 01`, album
  `New Title`, artist `New Artist`. The file name has the title.
- **Hopeless by name (17):** `Track 09.MP3`, `Track01.mp3` (tag `Track01` too). These
  need the track print (bolt 059).
- **Already fine (the rest):** the matcher finds the song title inside `Kuku- Tizita`,
  `♡ ማረኝ ማረኝ መመኪያዬ ♡` and `ድንቅ አድርጎልኛል ቀሲስ ምንዳዬ ብርሀኑ`, and it drops
  "official video" and similar phrases. Junk artists (`@Maryam_Maryam2127`,
  `The Best Of Amharic I`) only affect the tie-break.

So the gain is the file-name fallback for junk tags, plus a better tie-break.

### Deliverables

`zema_core`, `lib/src/lyrics/track_tags.dart`:

- `cleanTag(String)`: drops `[...]`, `(128)`-style numbers, `@channel`, a trailing
  YouTube ID (` - fC2ZoJszdzg`), `Track N` / `TrackNN`, `CD N` and leading track
  numbers (`01 `, `01_`, `04 - `). Turns `_` into spaces.
- `isJunkTag(String?)`: empty after cleaning, or a placeholder (`New Title`,
  `New Artist (35)`, `Unknown`, `Untitled`, `<unknown>`).
- `matchTitle(Track)`: the cleaned title tag, or the cleaned file name when the tag is
  junk or the same as the file's track number.
- `matchArtist(Track)`: the artist tag, or null when it is junk, a channel (`@…`) or
  the same as the title.

`SongMatcher.match` uses `matchTitle` and `matchArtist`. The artist tie-break also
looks for the song's artist in the title, as `rank` already does. That covers story
criterion 3: the known artist is found and used. It doesn't need to be cut out,
because extra words don't hurt the containment match.

### Changed from the story

- **The length tie-break is deferred to bolt 060.** The song index (`song_index`,
  `CatalogEntry`) has no recording lengths. Adding them needs a migration and a hosted
  push. The track print solves the same ties.

### Acceptance

- Unit tests for each clean-up rule and placeholder.
- A scratch script runs old and new matching on the 98 files against a catalog of
  their real titles. The new matching links ≥ 8 more and none worse.
- The existing `track_matching_test.dart` and mobile link tests pass.
