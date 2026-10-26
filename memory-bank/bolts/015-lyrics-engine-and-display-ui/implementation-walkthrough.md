---
stage: implement
bolt: 015-lyrics-engine-and-display-ui
created: 2026-10-26T19:50:28Z
---

## Implementation Walkthrough: lyrics-engine-and-display-ui (bolt 7 of 9)

### Summary

Now Playing shows the linked song's lyrics.
- **Following the song**: the line being sung is highlighted and kept a third of the way down the view.
- **Seeking**: tapping a line seeks to it.
- **Options sheet**: transliteration, text size, and a sync offset saved for each recording.

### Files

- **`lib/features/lyrics/application/lyrics_prefs.dart`**
  - `LyricsDisplay` and `lyricsDisplayProvider`:
    - the transliteration toggle
    - text scale: 0.8–1.6 in 0.1 steps, rounded so repeated steps don't drift
  - `lyricsOffsetProvider(recordingId)`:
    - stored as `lyricsOffset.<id>` in milliseconds
    - kept within ±10 s
    - removed from storage at zero
- **`lib/features/lyrics/application/track_lyrics.dart`**
  - `trackLyricsProvider(trackId)`: the linked song with its first recording and timing.
    - Gives null when no song is linked.
    - Timing that doesn't fit the song is logged and shown as plain lyrics.
  - `lyricsShiftProvider`: the recording's own offset plus the user's offset.
  - `currentLineProvider(trackId)`: the line index from `SyncEngine.at`. Widgets rebuild only when it changes.
- **`lib/features/lyrics/presentation/lyrics_view.dart`**
  - **`LyricsView` (C06)**:
    - Line colours: `primaryText` and bold for the current line, `faint` for past lines, `muted` for later ones. Plain lyrics use `text` and can't be tapped.
    - The first line of each chorus repeat has a "Chorus" label, and each line can show its transliteration.
    - Tapping a line seeks to `startOf(i, offset: shift)`.
    - Auto-scroll uses `Scrollable.ensureVisible(alignment: 0.33)`, with padding above and below so the first and last lines can reach that point. A user scroll pauses it until 3 s after the last touch, and a text size change re-centres the current line.
  - **`NoLyrics`**: an icon, "No lyrics for this song" and **Match lyrics**, which opens bolt 014's picker.
  - **`LyricsPreview`**: the current line, or the first line, in the panel under the artwork; tapping it opens lyrics mode.
- **`lib/features/lyrics/presentation/lyrics_options_sheet.dart`**
  - the transliteration switch
  - A−/A+ with the size as a percentage
  - for synced lyrics, a sync timing stepper (− / value / +) and **Reset timing**
  - `formatOffset`: "+1.0 s", "−0.5 s", "0.0 s"
- **`now_playing_screen.dart`**
  - `nowPlayingLyricsModeProvider` (for the session)
  - a lyrics button in the secondary actions
  - In lyrics mode, the title and artist sit above the lyrics view, and the artwork and panel are hidden. The view is keyed by track ID, so a new track starts at the top.
- **ARB**: 12 new strings; `playerNoLyrics` now reads "No lyrics for this song".

### Decisions

- Plain Flutter scrolling (a `GlobalKey` per line) rather than a package; songs are short.
- The view uses the song's first recording. Choosing between recordings comes with the cloud catalog.
- Lyrics mode lasts for the session, not across restarts.

### Emulator Check (release build)

- **Under the artwork**: the panel showed "Waaqayyo nu jaallatee" while that line was sung.
- **Lyrics mode**:
  - The verse lines and the three chorus repeats showed, with the labels.
  - The highlight followed the audio, and the view scrolled from line 3 to line 6 while playing.
- **Tap to seek**: tapping the second chorus moved playback to 0:26, its start.
- **Options sheet**: shows the switch, 100% text size, and 0.0 s timing.
- **Noted**:
  - Lines scrolled to the top run up against the artist name.
  - The options button sits over the first visible line.
  - Both are cosmetic; I'll consider a top fade in the test stage.
