---
stage: plan
bolt: 044-contribution-and-sync-editor-ui
created: 2026-11-02T14:00:00Z
---

## Implementation Plan: contribution-and-sync-editor-ui (bolt 3 of 11)

### Objective

S19's lyrics editor (story 004). It has blocks with a kind, a play order strip, and
Paste all text. Next stays off until the lyrics pass the shared rules.

### Deliverables

- **`lyrics_step.dart`**, under the song details:
  - **The chorus hint.**
  - **One card per block**, in the design's layout:
    - a kind menu (Verse, Chorus, Bridge or Other)
    - a ⋯ menu: Move up, Move down, Latin letters, Delete
    - a multi-line field, one line per row
  - **Add block** and **Paste all text** (a dialog that uses `splitPastedLyrics`).
  - **The play order**, as pills. Tap one to move it earlier or later, or remove it;
    **+ Add** appends a block.
  - **Next: link a recording.**
- **A step strip** across the top of the flow (Lyrics, Recording, Sync, Review).
- **37 English strings.**

### Decisions (recommended options)

- **Lines are typed as text, one per row**, as in the design, rather than a field per
  line.
  - Empty rows at the end are ignored.
  - An empty row in the middle is an error: "add a block instead".
  - Latin letters are a second field with one row per line.
- **The default play order follows the blocks.** It starts as each block once, in
  order. While it's still that, adding, moving or deleting a block keeps it in step.
  Once the user edits it, only deletions change it.
- **Deleting a block asks first when it has text**, or when it's in an edited play
  order. The message counts its play order entries.
- **Reordering the play order uses menus, not dragging.** That works with TalkBack and
  inside a wrapping row.
- **Block ids stay the same when the kind changes**, so the play order stays valid.
  Labels are worked out from the kind and position (Verse 1, Chorus, Bridge 2).
- **Next only moves the draft to the recording step.** Step 2 arrives in bolt 045;
  until then, the flow shows the lyrics at every step.
