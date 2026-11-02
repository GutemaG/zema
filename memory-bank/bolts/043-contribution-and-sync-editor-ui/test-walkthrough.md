---
stage: test
bolt: 043-contribution-and-sync-editor-ui
created: 2026-11-02T13:10:00Z
---

## Test Report: contribution-and-sync-editor-ui (bolt 2 of 11)

### Summary

- **Tests**: app 1,053, of which 29 are new; `zema_core` 293, of which 10 are new. All
  passing. Analyze and format are clean.
- **Planted bugs**: 17, all caught.
  - Four first showed up as hanging runs rather than failures. A teardown now closes
    the app inside each test, so every one fails in about a second (see Issues Found).
- **Emulator** (the owner's Medium Phone, API 37, with the local backend):
  - The app was built and run.
  - The Contribute tab shows S05 as designed.
  - Add lyrics as a guest opens C09 with the contributing reason.
  - The signed-in draft check waits for the owner to sign in (see Not Checked).

### Test Files

- [x] `packages/zema_core/test/contribute/contribution_draft_test.dart` (10):
  - **JSON**:
    - an empty draft round-trips, and a full one does too, with untapped starts
    - a newer format or malformed input is refused
    - an unknown step opens at the lyrics
  - **`toContribution`**:
    - a new song gets a slug from its transliteration, with blanks dropped
    - its recording belongs to the new song
    - timings are included only when synced
    - a correction keeps its song and base version; a recording and a sync are built
      right
  - **`lyricsErrors`**, and **`copyWith`** clearing the recording or track.
- [x] `apps/mobile/test/app/database/drafts_dao_test.dart` (5):
  - create, get and save keep the draft and its times, with the title, step and kind
    for the list
  - saving a deleted draft does nothing
  - the list shows last changed first and leaves out drafts it can't read; titles
    include them
  - clear removes every draft
  - times are stored as UTC
- [x] `apps/mobile/test/app/database/zema/migration_test.dart` (+1): v7 → v8 keeps
  tracks and kept entries, and starts with no drafts. The generated simple migrations
  run up to v8.
- [x] `apps/mobile/test/app/database/schema_test.dart`: version 8, thirteen tables.
- [x] `apps/mobile/test/features/contribute/contribute_screen_test.dart` (17):
  - **Guests**:
    - They see the steps, and Add lyrics opens C09 with the reason.
    - Not now starts nothing.
    - Signing in through C09 starts the draft and opens the flow.
  - **No backend**: a note, with no Add lyrics.
  - **Drafts**:
    - Typing is saved after the delay (not before), title and artist, and listed on
      S05 with its step.
    - A change is saved when the flow closes at once.
    - A change is saved at once when the app goes to the background.
    - They're listed last changed first, and one opens with what was typed.
    - An untitled draft shows as Untitled.
    - Delete only after confirming; Cancel keeps it.
    - A saved draft is there in a new app instance with the same database (as after a
      kill).
    - A title over 200 characters is flagged. A missing draft says so.
  - **Signing out**:
    - The confirmation names the drafts (including Untitled), and confirming deletes
      them.
    - With no drafts, the message is unchanged.
    - Deleting the account names them too.
  - **Fit**: S05 with a long Ethiopic draft title and the flow, at 1.3× on 360 × 640,
    dark and light.
- [x] `apps/mobile/test/app/app_shell_test.dart`: the "unbuilt tab shows Coming soon"
  test is removed, because no tab is unbuilt any more. The scroll test uses the new
  Contribute list.

### Acceptance Criteria Validation

- ✅ **A guest sees the explanation; Add lyrics opens C09; after sign-in a draft
  starts**: guest tests, and on the emulator (C09).
- ✅ **Signed in: steps, Add lyrics, and drafts with title, step and last changed**:
  drafts tests.
- ✅ **Every change saved within a second; a new app instance shows it**: the
  delay, close, background and new-instance tests.
- ✅ **Drafts open at their step; delete with confirmation**: the open and delete
  tests. Only step 1 exists, so all drafts open there.
- ✅ **Signing out names the drafts and deletes them**: the signing-out tests.
- ✅ **No backend: actions hidden**: no-backend test.
- ✅ **Migration v7 → v8 keeps the data**: migration test.
- ✅ **Fits at 1.3× on a small phone, dark and light**: fit tests.
- ⚠️ **Checked on the emulator**:
  - S05 and C09 were checked as a guest.
  - Typing a draft, killing the app and finding it again needs a signed-in user. That
    waits for the owner to sign in on the emulator.

### Planted Bugs (17, all caught)

- **Saving**: no delayed save; no save on close; no save on pause.
- **The list**: oldest first; save keeps the old time; an unreadable draft crashes the
  list; the title not stored for the list.
- **Account**: sign-out keeps drafts; no drafts warning.
- **S05**: guests not asked to sign in; the button shown without a backend; delete
  without confirming.
- **The flow**: a long title not flagged; the artist not saved.
- **Database**: no v8 table.
- **The model**: starts not kept; timings sent before synced.

### Issues Found

- **A failing test left a pending save and the run never ended.**
  - The framework closed a failed test's app outside the fake clock, and its database
    streams never finished closing.
  - Each test now closes the app itself in a teardown, then lets saves finish.
  - Four planted bugs now fail in about a second instead of hanging.
- **Awaiting a Drift stream's `.first` hangs in widget tests** (known since 038). The
  tests use plain selects.

### Not Checked / Follow-ups

- **The signed-in draft check on the emulator**: sign in, type a draft, kill the app,
  reopen it and find the draft. This waits for the owner's sign-in; I don't sign in
  with their Google account.
