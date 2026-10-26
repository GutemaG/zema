---
stage: plan
bolt: 015-lyrics-engine-and-display-ui
created: 2026-10-26T19:32:18Z
---

## Implementation Plan: lyrics-engine-and-display-ui (bolt 7 of 9)

### Objective

Show the linked song's lyrics on Now Playing (stories 012 and 013).
- **Synced lyrics**: the line being sung is highlighted, and the view scrolls to follow it.
- **Seeking**: tap a line to seek to it.
- **Display options**: a transliteration toggle and A−/A+ text size.
- **Sync offset**: adjust it in 0.5 s steps; it is saved per recording.

### Deliverables

- **`features/lyrics/application/track_lyrics.dart`**
  - `trackLyricsProvider(trackId)`:
    - takes the linked song, its first recording and that recording's timing
    - gives `TrackLyrics`: the song, its sung lines, the `SyncedLyrics` (null when there is no timing) and the recording ID
    - gives null when no song is linked
  - `currentLineProvider`: `SyncEngine.at(position, offset)` → the current line index. It only changes when the line changes, not on every position tick.
- **`features/lyrics/data/lyrics_prefs.dart`** (`shared_preferences`) and a `LyricsPrefsController`
  - the transliteration toggle, off by default
  - text scale: 0.8–1.6 in 0.1 steps
  - a sync offset per recording ID (`lyricsOffset.<id>`), kept within ±10 s
  - The Settings screen entries come in bolt 017.
- **`features/lyrics/presentation/lyrics_view.dart`** (C06)
  - **Lines**: the current line uses `primaryText` and a bolder weight; past lines are `faint`; later lines are `muted`. The first line of each chorus repeat has a small "Chorus" label.
  - **Tap a line**: seeks to `engine.startOf(i, offset)`. Plain lyrics (no timing) have no highlight and no tap action.
  - **Transliteration**: when the toggle is on, each line's transliteration shows below it in a smaller size.
  - **Auto-scroll**: keeps the current line about a third of the way down the view.
    - Scrolling by hand pauses it; it resumes 3 s after the last touch.
    - A text size change re-centres the current line.
- **`features/lyrics/presentation/lyrics_options_sheet.dart`**
  - the transliteration switch and A−/A+
  - for synced lyrics: an offset stepper (−0.5 s / +0.5 s / Reset) showing the current value, e.g. "+1.0 s"
- **Now Playing**
  - A lyrics/artwork switch in `_SecondaryActions`.
  - In lyrics mode, the artwork area and the current "No lyrics" panel give way to the lyrics view; the title, seek bar and controls stay.
  - In artwork mode, the small panel shows the current line (or "No lyrics"); tapping it opens lyrics mode.
  - The mode lasts for the session.
- **No lyrics state**: "No lyrics for this song" with a **Match lyrics** button. It opens bolt 014's picker.
- **Track changes**: the view switches song and scrolls back to the top.
- **Strings**: about 12 new, in all four languages (English text as the placeholder, as before).

### Dependencies

- Bolts 012 and 013: `SyncedLyrics`, `SyncEngine`, `LyricsRepository`
- Bolt 014: `trackSongProvider` and `showMatchLyricsSheet`
- Intent 002: `positionProvider`, `PlayerController.seek`, Now Playing

### Technical Approach

- The engine does a binary search per position tick. The view rebuilds only when the line index changes, using `select` on a derived provider.
- Scrolling uses a `ScrollablePositionedList`-like approach with plain Flutter: a `GlobalKey` per line and `Scrollable.ensureVisible(alignment: 0.33)`. This avoids a new package.
- The 3 s pause uses `NotificationListener<UserScrollNotification>` and a `Timer` that restarts on each touch. Auto-scroll animations are not counted as user scrolls.
- The offset is applied as `engine.at(position, offset: …)`, so a change moves the highlight on the next frame.

### Acceptance Criteria

- [ ] Synced: current line highlighted, past lines faint, chorus marked; tapping a line seeks to it
- [ ] Plain lyrics show without highlight; with no linked song, the No lyrics state with Match lyrics shows
- [ ] The transliteration toggle shows the transliteration under each line
- [ ] Auto-scroll follows the current line, pauses on a manual scroll and resumes after 3 s
- [ ] Offset ±0.5 s steps move the highlight at once, are saved per recording, and are clamped to ±10 s
- [ ] A−/A+ keeps the current line in view
- [ ] A track change switches the lyrics
- [ ] 1.3× text in light and dark: no overflow
- [ ] Emulator: a sample song highlights in time with its audio
- [ ] Analyze and format clean; tests pass
