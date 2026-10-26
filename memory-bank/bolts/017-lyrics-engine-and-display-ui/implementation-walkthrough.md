---
stage: implement
bolt: 017-lyrics-engine-and-display-ui
created: 2026-10-26T20:42:06Z
---

## Implementation Walkthrough: lyrics-engine-and-display-ui (bolt 9 of 9)

### Summary

Settings has a Lyrics section with text size, show transliteration and a default sync timing. It uses the same settings as Now Playing and Song detail, so a change applies everywhere at once.

### Files

- **`lib/features/lyrics/application/lyrics_prefs.dart`**
  - **Default offset**:
    - `LyricsDisplay.defaultOffset` is saved as `lyricsDefaultOffset`.
    - `nudgeDefaultOffset` steps by 0.5 s.
    - `clampOffset` (±10 s) is shared.
  - **Per-recording offset**: `lyricsOffsetProvider` is now `Duration?`, where null means the recording has none of its own.
    - `effective` gives the recording's own offset, or the default.
    - `nudge` starts from `effective` and saves the result as the recording's own.
    - `reset` removes the recording's own offset.
- **`track_lyrics.dart`**: `lyricsShiftProvider` = the recording's offset + (the user's own offset for it ?? the default).
- **`lyrics_options_sheet.dart`**
  - shows the offset in effect
  - Reset is enabled only when the recording has its own offset
  - the stepper row is now the public `LyricsStepper`
- **`lyrics_settings_group.dart`** (new): the Lyrics section, shown in `settings_screen.dart` between Playback and About.
- **ARB**: 3 new strings.

### Decision

- **Settings storage**: these settings stay in `lyricsDisplayProvider` rather than `AppSettings`, so there is one shared copy (see the plan).

### Emulator Check (release build, Wi-Fi and data off)

- **Home**: Continue listening, Recently played and playlists; no "Coming soon".
- **Settings**: the Lyrics section shows Text size 100%, the transliteration switch, Default sync timing 0.0 s and its note.
- **Search**: "kidist" found "Kidus Kidus" and "ቅዱስ ቅዱስ ቅዱስ". adb can't type Ethiopic, so "ቅድስት" and "ቅዱስት" are checked by the core tests.
