---
stage: implement
bolt: 044-contribution-and-sync-editor-ui
created: 2026-11-02T14:30:00Z
---

## Implementation Walkthrough: contribution-and-sync-editor-ui (bolt 3 of 11)

### Summary

S19 now has the lyrics editor:
- blocks with a kind and a menu
- Latin letters per line
- Paste all text
- the play order strip
- Next, enabled only when the lyrics pass `songErrors`

Every edit goes through the draft editor from bolt 043, so it's saved as you type.

### Completed Work

- [x] `apps/mobile/lib/features/contribute/presentation/lyrics_step.dart`:
  - **`LyricsStep`**: keeps one text controller per block, keyed by block id. Pasting
    clears them and bumps a generation number, so the cards rebuild.
  - **`_BlockCard`, `_PlayOrder`, `_Pill`, `_PasteDialog`.**
  - **Helpers**: `sectionLabel`, `newSectionId` and `linesFromText`.
- [x] `contribute_flow_screen.dart`:
  - `StepStrip`, and the flow shows `LyricsStep` under it.
  - The old step-1-only `_LyricsStep` is removed.
- [x] `app_en.arb`: 37 strings (`contributeBlock*`, `contributePlayOrder*`,
  `contributePaste*` and others).

### Deviations

- **No "Save draft" button in the app bar** (the design has one). Drafts save as you
  type, and the screen says so.
