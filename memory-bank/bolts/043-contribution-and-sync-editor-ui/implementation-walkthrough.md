---
stage: implement
bolt: 043-contribution-and-sync-editor-ui
created: 2026-11-02T12:40:00Z
---

## Implementation Walkthrough: contribution-and-sync-editor-ui (bolt 2 of 11)

### Summary

The Contribute tab is now S05. It has "How contributing works", Add lyrics (with C09
for guests), and the user's drafts. A draft opens the contribution flow, which so far
has step 1's song details. Every change is saved on the phone shortly after it's made,
at once when the app goes to the background, and when the flow closes. Signing out or
deleting the account warns about drafts by title, and deletes them.

### Structure Overview

- **`ContributionDraft`** (in `zema_core`) is the whole work in progress, stored as
  JSON in a new Drift table, along with a title and step for the list.
- **A family of editor notifiers** holds one open draft each.
  - Edits change the state at once.
  - The save is debounced and serialized.
  - It's flushed on pause and on dispose.
- **S05 lists the drafts** from a Drift stream. The flow screen opens above the shell
  at `/contribute-draft?id=N`.

### Completed Work

- [x] `packages/zema_core/lib/src/contribute/contribution_draft.dart`:
  - `DraftStep` and `ContributionDraft`, with JSON (a format number), `toContribution`,
    `lyricsErrors`, `synced` and `copyWith`.
- [x] `apps/mobile/lib/app/database/tables.dart`: the `Drafts` table.
- [x] `apps/mobile/lib/app/database/drafts_dao.dart`: `SavedDraft` and `DraftsDao`
  (watch all, get, create, save, remove, clear, titles).
- [x] `apps/mobile/lib/app/database/zema_database.dart`: schema v8 with `from7To8`.
  - Generated `zema_database.steps.dart`, `drift_schemas/zema/drift_schema_v8.json`
    and `test/.../generated/schema_v8.dart`.
- [x] `apps/mobile/lib/features/contribute/application/drafts.dart`:
  `draftsProvider`, `startDraft`, `deleteDraft`, and `draftEditorProvider`
  (`DraftEditor`).
- [x] `apps/mobile/lib/features/contribute/presentation/contribute_screen.dart`: S05.
- [x] `apps/mobile/lib/features/contribute/presentation/contribute_flow_screen.dart`:
  the flow, with step 1's details.
- [x] `apps/mobile/lib/app/routes.dart` and `router.dart`: `draftPath` and
  `AppRoutes.draft(id)`.
- [x] `apps/mobile/lib/features/account/presentation/profile_screen.dart`: the
  sign-out and delete confirmations name the drafts.
- [x] `apps/mobile/lib/features/account/application/profile.dart`: sign-out and
  delete clear the drafts.
- [x] `apps/mobile/lib/l10n/app_en.arb`: 29 new strings. The old "Contribute coming
  soon" message is removed from every ARB.

### Key Decisions

- **The draft keeps a `Song`, with an empty ID for a new song.** The slug is proposed
  only when sending, so changing the title never leaves a stale ID.
- **Starts are a list with nulls for lines not tapped yet**, so a half-synced draft
  saves and reopens as it was.
- **Saving waits 300 ms after the last change.** Each keystroke isn't a database
  write, and everything is still saved within a second.
  - Pausing the app saves at once.
  - Closing the flow saves at once, through the notifier's dispose.
- **Drafts aren't tied to an account in the table.** The story says drafts stay on this
  phone and go on sign-out. Clearing them on sign-out and on account deletion keeps
  them from passing to another account.
- **Times are shown with the backup screen's formatter** (date and time in the user's
  language), not relative times. Intl has no Afaan Oromoo or Tigrinya data for
  relative formats.

### Deviations from Plan

- **The S05 header has no avatar**: Profile is on Home. **The stats row, "Sync a song"
  and "Needs sync"** come with bolts 049–050, as planned.
- **Delete account also deletes drafts**, and its first confirmation names them. The
  story only mentioned sign-out, but the account the drafts were for is gone.

### Dependencies Added

None.

### Developer Notes

- **Don't await a Drift stream's `.first` in widget tests**: it hangs. The tests read
  drafts with plain selects, as bolt 038 found.
- **The test binding stops frames while "paused".** The background-save test goes into
  the background and back without time passing, then checks the database before the
  300 ms delay.
