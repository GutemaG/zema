---
stage: plan
bolt: 017-lyrics-engine-and-display-ui
created: 2026-10-26T20:35:39Z
---

## Implementation Plan: lyrics-engine-and-display-ui (bolt 9 of 9)

### Objective

Add a Lyrics section to Settings (story 016): text size, show transliteration, and a default sync offset. Then run intent 003's done-when checks on the emulator and close the intent.

### Deliverables

- **Default sync offset**
  - `lyricsDisplayProvider` gains `defaultOffset`:
    - saved as `lyricsDefaultOffset` in milliseconds
    - steps of 0.5 s, within ±10 s
  - `lyricsOffsetProvider(recordingId)` changes:
    - It becomes `Duration?`, which is null when the recording has no offset of its own.
    - The total offset uses the recording's own offset when set, otherwise the default. A recording's own offset always wins.
  - **Options sheet on Now Playing**:
    - shows the offset in effect
    - "+" or "−" saves an offset for that recording
    - Reset goes back to the default
- **`features/settings/presentation/settings_screen.dart`**: a new **Lyrics** section between Playback and About, with:
  - **Text size**: A− / percentage / A+
  - **Show transliteration**: a switch
  - **Default sync offset**: − / value / + and a note that a song's own timing wins
  - It reuses the stepper row from the options sheet, moved to a shared `LyricsStepper` widget.
- **Done-when checks for intent 003**, run on the emulator and written in the test walkthrough:
  - Home and Search show real content offline, with no "Coming soon" on those tabs.
  - Highlight accuracy within ±0.3 s: a test drives positions just before and after each line's start.
  - "kidist", "ቅድስት" and "ቅዱስት" find the same song (already a test; checked again on the emulator).
  - Core unit tests cover sync, play order, normalization, LRC and matching.
- **Strings**: about 4 new.

### Technical Approach

- **Why not `AppSettings`**: the story's note says to extend it, but these settings already live in `lyricsDisplayProvider` (bolt 015). Keeping them there gives Now Playing, Song detail and Settings one shared source, with no second copy to keep in step.
- **Old saved offsets**: an existing saved offset of 0 is never stored (Reset removes the key), so saved data needs no migration.

### Acceptance Criteria

- [ ] Settings has a Lyrics section with text size, show transliteration and default sync offset
- [ ] Changes apply to the lyrics view and Song detail at once, and persist
- [ ] A recording's own offset wins over the default; Reset returns to the default
- [ ] 1.3× text in light and dark: no overflow
- [ ] Intent done-when checks pass, including the ±0.3 s accuracy test
- [ ] Analyze and format clean; tests pass
