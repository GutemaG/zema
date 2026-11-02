---
stage: implement
bolt: 047-contribution-and-sync-editor-ui
created: 2026-11-02T17:20:00Z
---

## Implementation Walkthrough: contribution-and-sync-editor-ui (bolt 6 of 11)

### Completed Work

- [x] `apps/mobile/lib/features/lyrics/presentation/lyrics_view.dart`:
  - `_Lines` is now a small widget that reads the main player's providers and passes
    them to the new public **`LyricsLines`**.
  - `LyricsLines` follows the current line in `didUpdateWidget`, not through provider
    listeners.
- [x] `apps/mobile/lib/features/contribute/presentation/sync_step.dart`:
  - **`_View`** (list, focus, preview), with `_ViewBar` and `_FocusView`.
  - **Preview** builds `LyricsLines` with `lineAt(starts, position)`. Tapping a timed
    line seeks to it.
  - **`_startPreview` and `_endPreview`.**
  - **The list's bottom row** is just Undo; Skip is in the menu.
- [x] `packages/zema_core/lib/src/contribute/sync_editing.dart`: `lineAt`.
- [x] `app_en.arb`: 8 strings. `contributeSyncPressPlay` now reads "Play to start".
