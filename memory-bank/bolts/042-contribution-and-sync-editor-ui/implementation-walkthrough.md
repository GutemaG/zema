---
stage: implement
bolt: 042-contribution-and-sync-editor-ui
created: 2026-11-02T11:00:00Z
---

## Implementation Walkthrough: contribution-and-sync-editor-ui (bolt 1 of 11)

### Summary

`zema_core` now has the contribution model, the shared rules, and the text helpers
the editor needs: paste-split, YouTube link parsing, and proposed song IDs.
`zema_data` has a repository over the backend's contribution functions. Every refusal
the backend names reaches the app as a typed failure with its code. The app's tests
get an in-memory fake that follows the same rules.

### Structure Overview

- **`zema_core/lib/src/contribute/`** holds everything that's pure Dart:
  - the model (four kinds, each carrying part of 004's song document)
  - the rules, which return every broken rule once, in the backend's order
  - the text helpers
  - the repository interface
- **`Recording`** gains the source reference (`youtubeId`, `fileName`) that 041's
  documents carry.
- **`zema_data`'s repository** wraps 005's `run`, so sessions and network errors are
  handled as for backups. Known codes become `ContributionFailure`s before the general
  mapping.

### Completed Work

- [x] `packages/zema_core/lib/src/contribute/contribution.dart`:
  - kinds, statuses and decisions, with their wire names
  - `Contribution` and its payload round trip
  - `SubmittedContribution` and `QueuedContribution`
- [x] `packages/zema_core/lib/src/contribute/contribution_rules.dart`:
  - **`ContributionError`**: all 35 backend codes.
  - **Limits as constants**, and the slug and video ID checks.
  - **The rule functions**: song, recording, timing and contribution.
  - **`ContributionFailure.error`**.
- [x] `packages/zema_core/lib/src/contribute/paste_lyrics.dart`: `splitPastedLyrics`.
- [x] `packages/zema_core/lib/src/contribute/youtube.dart`: `youtubeVideoId`.
- [x] `packages/zema_core/lib/src/contribute/song_slug.dart`: `proposeSongSlug` and
  `newRecordingId`.
- [x] `packages/zema_core/lib/src/contribute/contribution_repository.dart`: the
  interface.
- [x] `packages/zema_core/lib/src/lyrics/lyrics_models.dart`: `Recording.youtubeId`
  and `Recording.fileName`.
- [x] `packages/zema_core/lib/src/failures.dart`: `ContributionFailure`.
- [x] `packages/zema_core/lib/zema_core.dart`: exports.
- [x] `packages/zema_data/lib/src/supabase_contribution_repository.dart`: submit,
  resubmit, mine, queue and review, with the code mapping.
- [x] `packages/zema_data/lib/zema_data.dart`: export.
- [x] `backend/supabase/migrations/20261102030000_set_moderator_definer.sql`:
  `set_moderator` runs as its owner (a fix to bolt 040).
- [x] `apps/mobile/test/helpers/fake_contributions.dart`:
  `FakeContributionRepository`.

### Key Decisions

- **One named constructor per kind.** A new song can't carry a song ID, and a sync
  can't carry a song.
- **The rules return all broken rules, not just the first.** Editors can mark every
  field at once. The order matches the backend's, so the first one is what the backend
  would say.
- **Checks needing the catalog are optional.** The sung-line count of an existing song
  and a sync's recording take `currentSong` and `existingRecording`. Without them,
  those checks are left to the backend.
- **The song ID for a new song is only a proposal.** It comes from the transliteration
  when there is one; otherwise Ethiopic words become their consonants. The backend
  makes it unique on approval.
- **Recording IDs are random lower-case UUIDs** (pure Dart, `Random.secure`). They're
  also valid slugs.
- **`not_signed_in` becomes an `AuthFailure`**, like every other sign-in problem.
  Other known codes, the limits and `already_reviewed` included, become
  `ContributionFailure`s, so the screens switch on one type.

### Deviations from Plan

- **Added a migration that fixes bolt 040's `set_moderator`.** It looks users up in
  `auth.users`, which `service_role` can't read, so it worked only as the database
  owner. The backend test (granting with the service key) found it.
  - Now `security definer`, still executable only by `service_role`.
  - A pgTAP test calls it as `service_role`.
- **No `isModerator` on the repository.** `Profile.isModerator` (005) already gives
  it, as planned.

### Dependencies Added

None.

### Developer Notes

- **The backend tests read the local service key at run time** from `supabase
  status`, like the anon key. It's never printed or stored. They delete the songs and
  contributions they create, and the test users.
- **A parity test reads the two migration headers** and compares their codes with
  `ContributionError`. A new backend code fails it until Dart has it too.
- **Unrelated fix**: the home screen test's tracks were dated 2026-10-01, and Recently
  added covers 30 days, so from 2026-11-02 on, "Recently added opens its auto
  playlist" failed.
  - `scannedAudio` takes an optional `dateAdded`.
  - The home test dates its tracks yesterday.
