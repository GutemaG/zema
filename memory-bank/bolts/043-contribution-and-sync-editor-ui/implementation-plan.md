---
stage: plan
bolt: 043-contribution-and-sync-editor-ui
created: 2026-11-02T12:00:00Z
---

## Implementation Plan: contribution-and-sync-editor-ui (bolt 2 of 11)

### Objective

The Contribute tab becomes S05: how contributing works, Add lyrics, and the user's
drafts. Drafts are saved on the phone as the user types, and nothing is lost when the
app is killed. Story: `003-contribute-tab-and-drafts`. Recommended options;
checkpoints waived.

### Deliverables

- **`zema_core/lib/src/contribute/contribution_draft.dart`**: `ContributionDraft`, the
  work in progress of one contribution:
  - the kind, the target song and base version
  - the song so far, and the recording
  - one start per sung line (null until tapped)
  - the local track that opened it, and the current `DraftStep` (lyrics, recording,
    sync, review)
  - JSON with a format number, `toContribution()` (proposes the slug and sets the
    recording's song), `errors`, and `synced`
- **Drift schema v8**:
  - **The `Drafts` table**: ID, kind, step, title (for the list), the draft as JSON,
    created and updated times.
  - **`DraftsDao`**: watch all (newest first), get, create, save, delete, clear and
    titles.
  - The `from7To8` step, `drift_schema_v8.json` and the generated `schema_v8`.
- **`features/contribute/application/drafts.dart`**:
  - `draftsProvider`, a stream of the list.
  - `draftEditorProvider(id)`: it loads the draft, applies changes, and saves after
    300 ms of quiet (under 1 s). It also saves at once when closed or when the app goes
    to the background.
  - `startDraft()`, `deleteDraft()`.
- **`features/contribute/presentation/contribute_screen.dart`** (S05, design
  `05-contribute.png`):
  - the header ("Help everyone sing along")
  - the four-step "How contributing works" card
  - Add lyrics
  - Drafts: title (or "Untitled"), step, last changed; tap to continue; delete with
    confirmation
  - **Guests** see the card, and Add lyrics opens C09 with a contributing reason; after
    sign-in it continues.
  - **Builds without a backend** show the card, with a note in place of the actions.
- **`features/contribute/presentation/contribute_flow_screen.dart`**, above the shell
  at `/contribute/draft?id=N`:
  - It opens the draft at its step.
  - In this bolt only step 1's song details exist: title, transliteration, artist and
    album. Bolt 044 adds the block editor and play order, and 045–048 the other steps.
  - Close returns to S05; the draft is already saved.
- **Signing out with drafts**: Profile's confirmation names them ("2 drafts on this
  phone will be deleted: Selam, Tizita"), and signing out deletes them. Delete account
  deletes them too, and its first confirmation names them.
- **English strings** (`app_en.arb`).
- **Tests**:
  - the draft model
  - the DAO
  - the v7 → v8 migration
  - S05 for guests, signed in, and with no backend
  - the drafts list: open, delete, newest first
  - autosave, including a draft surviving a new app instance (as after a kill)
  - the sign-out and delete warnings, and clearing
  - fit at 1.3× on a small phone, dark and light
- **Emulator**: run the app; the Contribute tab; a draft typed, the app killed, the
  draft still there.

### Deviations

- **"My contributions" on S05 comes with S23 (bolt 050).** Showing the link now would
  open a screen that doesn't exist yet. The design's stats row also comes in 050, and
  "Needs sync" and "Sync a song" in 049.
- **English only.** The Amharic, Afaan Oromoo and Tigrinya ARB files have no
  translated strings yet in any intent, so 006 follows the project's "English first"
  rule rather than NFR "four languages". Translating is a separate pass.

### Acceptance Criteria

- [ ] A guest sees the explanation, and Add lyrics opens C09; after sign-in a draft
  starts.
- [ ] Signed in: the steps, Add lyrics, and the drafts with title, step and last
  changed.
- [ ] Every change is saved within a second, and a new app instance (after a kill)
  shows it.
- [ ] Drafts open at their step, and can be deleted with confirmation.
- [ ] Signing out names the drafts, and confirming deletes them.
- [ ] No backend: the actions are hidden.
- [ ] Migration v7 → v8 keeps the data.
- [ ] Fits at 1.3× on a small phone, dark and light.
- [ ] Analyze, format and all tests pass; checked on the emulator.
