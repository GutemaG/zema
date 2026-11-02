---
stage: test
bolt: 044-contribution-and-sync-editor-ui
created: 2026-11-02T15:00:00Z
---

## Test Report: contribution-and-sync-editor-ui (bolt 3 of 11)

### Summary

- **Tests**: app 1,069, of which 16 are new. All passing. Analyze and format are clean.
- **Planted bugs**: 7, all caught.
- **Emulator**:
  - The new build is installed and running.
  - S19 can't be reached without signing in. The owner hasn't signed in on the
    emulator yet, so the check waits for that (see Not Checked).

### Test Files

- [x] `apps/mobile/test/features/contribute/lyrics_step_test.dart` (16):
  - **Helpers**:
    - labels (verses always numbered, other kinds only when repeated)
    - new ids take the first free one per kind
    - lines from text: trailing empty rows dropped, Latin letters matched by row
  - **The screen**:
    - the details, hint and step strip show; no play order without blocks
    - blocks are added, typed and given a kind, and the default play order follows
    - moving a block keeps the default order in step
    - play order entries are added, moved earlier and later, and removed; an edited
      order no longer follows new blocks
    - deleting a block in the play order asks, Cancel keeps it, and confirming
      removes its entries
    - an empty block is deleted without asking
    - Paste all text gives `splitPastedLyrics`' blocks and order; they can be edited
      afterwards
    - pasting over blocks says it replaces them, and Cancel keeps them
    - Latin letters per line are saved
    - Next stays off for an empty block, an empty row (with its error) or an empty
      play order, and moves the draft to the recording step once the lyrics are valid
    - a line over 500 characters is flagged
  - **Fit**: S19 with five blocks and a long Ethiopic line, at 1.3× on 360 × 640,
    dark and light, with a block menu open.

### Acceptance Criteria Validation

- ✅ **Fields and the block editor show**: the first screen test. The cards follow
  `06-add-lyrics.png`.
- ✅ **Blocks can be added, deleted and reordered, with Latin letters per line**:
  the block tests.
- ✅ **Play order entries can be added, removed and reordered; the default is each
  block once**: the play order tests.
- ✅ **Paste all text uses `splitPastedLyrics` and can be changed**: the paste test.
- ✅ **Invalid lyrics keep Next off and show the error**: the Next and long-line
  tests.
- ✅ **Fits at 1.3× on a small phone, dark and light**: the fit tests.
- ✅ **Edge case: deleting a block in the play order removes its entries after
  confirming**: the delete test.

### Planted Bugs (7, all caught)

- the play order ignores new blocks
- deleting keeps its entries
- no delete confirmation
- paste ignores the play order
- Latin letters dropped
- Next always on
- no empty-row error

### Issues Found

- **Multi-line fields scroll themselves**, so scrolling the screen in tests names the
  list.
- **A literal "+" on the Add pill failed the no-string-literals check.** It's an icon
  now.

### Not Checked

- **S19 on the emulator**: this waits for the owner to sign in, as in bolt 043.
