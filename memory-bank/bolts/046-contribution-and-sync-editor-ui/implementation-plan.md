---
stage: plan
bolt: 046-contribution-and-sync-editor-ui
created: 2026-11-02T16:10:00Z
---

## Implementation Plan: contribution-and-sync-editor-ui (bolt 5 of 11)

### Objective

S21's List view (story 007): tap along with the recording to time every sung line.

### Deliverables

- **`zema_core` `sync_editing.dart`**, pure functions over the starts:
  - `nextUntimed`, `tapNext`, `undoLastTap`, `nudgeStart`, `redoFrom`,
    `redoPosition`, `startsFor`
  - starts always rise by at least 0.1 s
- **`SyncPlayer`**: a separate just_audio player behind an interface, with a fake for
  tests.
- **`SyncStep`**:
  - **The playback bar**: a seek slider, position over length, −5 s, 0.75× or 1×, and
    play/pause.
  - **A row per line occurrence**, in play order, with its time or —. The next line is
    outlined with "Tap when this line starts".
  - **Tapping a timed row** opens −0.1 s and +0.1 s (hold to repeat) and Redo from
    here.
  - **Undo last tap**, and **Skip, send text only**.
  - **The big button**: "Press play…", then "Tap — next line", then "Next: review"
    once every line is timed.
- **Opening S21 pauses the main player.** Going to the background pauses the sync
  player, and closing frees it.

### Decisions (recommended options)

- **The playback bar is a plain slider, not a waveform.** The story allows this, and
  it saves decoding the audio.
- **A tap that isn't at least 0.1 s after the previous line is ignored.** That happens
  after seeking back, and it keeps the backend's rising-order rule.
- **If the lyrics' line count changed since timing, the starts start over.**
- **No step or line counters**, as the owner asked.
