---
stage: implement
bolt: 048-contribution-and-sync-editor-ui
created: 2026-11-02T19:20:00Z
---

## Implementation Walkthrough: contribution-and-sync-editor-ui (bolt 7 of 11)

### Completed Work

- [x] `apps/mobile/lib/features/contribute/presentation/review_step.dart`:
  - **`ReviewStep`**: four `_Section` cards (Song, Lyrics, Recording,
    Timings), each with Edit. Edit has a screen-reader label naming its part.
  - Timings' Edit goes to the recording step when there's nothing to sync
    (no recording, or YouTube).
  - **`syncStatusOf`** and **`submitProblem`** (failure → message; the limits
    name their numbers).
- [x] `.../contribute/application/own_copies.dart`:
  - **`submitDraft`**: checks `draftErrors`, sends, then in one transaction
    saves the own copy and removes the draft row. It doesn't use
    `deleteDraft`, so the shared file stays.
  - **`ownCopiesProvider`**, **`trackOwnCopyProvider`**.
  - **`OwnCopyReconciler`** and its provider.
- [x] `apps/mobile/lib/app/database/`:
  - `tables.dart`: **`OwnCopies`**.
  - `own_copies_dao.dart`: **`OwnCopy`** and **`OwnCopiesDao`**.
  - `zema_database.dart`: schema 9, `from8To9`. The generated files,
    `drift_schemas/zema/drift_schema_v9.json` and `test/.../schema_v9.dart`
    were regenerated.
- [x] `.../lyrics/application/track_lyrics.dart`: **`TrackLyrics.pending`**.
  The own copy is read first.
- [x] `.../lyrics/presentation/lyrics_view.dart`: **`PendingReviewChip`** at
  the top left of the lyrics.
- [x] `.../contribute/presentation/contribute_flow_screen.dart`: step 4 is
  `ReviewStep`. The `contributeStepLater` string is no longer used but stays
  in the ARB files.
- [x] `.../account/application/account_providers.dart`:
  **`contributionRepositoryProvider`**.
- [x] `.../account/application/profile.dart`: `_forget` clears the own copies
  and their shared files.
- [x] `packages/zema_core/.../contribution_rules.dart`: the two limits.
- [x] `app_en.arb`: 28 strings, appended at the end.
- [x] `test/helpers/pump_app.dart`: a `contributions` parameter (last), with
  an empty fake by default.
