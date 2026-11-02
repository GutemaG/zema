---
stage: plan
bolt: 047-contribution-and-sync-editor-ui
created: 2026-11-02T17:00:00Z
---

## Implementation Plan: contribution-and-sync-editor-ui (bolt 6 of 11)

### Objective

S21's Focus view and Preview (story 008).

### Deliverables

- **A view bar on S21**:
  - List and Focus, as icon toggles
  - Preview, which needs at least one time
  - a ⋮ menu holding "Skip, send text only"
- **The Focus view** (design `07b-sync-focus.png`, without the counter and progress
  segments):
  - the line before, with ✓ and its time
  - the next line to time, large, with its block (VERSE 1, CHORUS)
  - the line after
  - a big tap area: "Play to start", then "Tap when you hear it", with position and
    length
  - Undo, Play or Pause, and −5 s
- **Preview**: plays from 0:00 in the shared lyrics view (C06) and highlights by the
  times. "Back to syncing" pauses and returns to the view it came from.
- **`LyricsLines`**: split out of `LyricsView` (lines, current index, display, tap) so
  the song screen and the preview share it.
- **`zema_core`**: `lineAt(starts, position)`.

### Decisions (recommended options)

- **All views live in one `SyncStep` state.** Switching keeps the player, position,
  speed and times, and playback continues.
- **While paused, the big button and the tap area start playback** ("Play to start")
  instead of being disabled.
- **The view toggles are icons with tooltips, and Skip moved into the ⋮ menu.** At
  1.3× text on a 360 × 640 phone, the labelled bar and the Undo/Skip row each wrapped
  to two lines, leaving almost no room for the lines.
