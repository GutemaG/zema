---
stage: plan
bolt: 042-contribution-and-sync-editor-ui
created: 2026-11-02T10:00:00Z
---

## Implementation Plan: contribution-and-sync-editor-ui (bolt 1 of 11)

### Objective

The app's shared model and rules for contributions, plus the repository that talks to
bolts 039–041's server functions. Stories: `001-contribution-model-and-validation` and
`002-contribution-repository`. The owner asked to continue with my recommended
options, without checkpoints.

### Deliverables

- **`zema_core/lib/src/contribute/`**:
  - **`contribution.dart`**: the shared types.
    - Enums: `ContributionKind`, `ContributionStatus`, `ReviewDecision`. Each has the
      server's wire name.
    - **`Contribution`**: one named constructor per kind. `toPayload()` gives 004's
      song document shape, and `Contribution.fromPayload` reads it back.
    - **`SubmittedContribution`**: a contribution the user sent, with its status.
    - **`QueuedContribution`**: a moderator's view, with the author name and the
      current song.
  - **`contribution_rules.dart`**: the shared rules.
    - **`ContributionError`**: every server code from 039 and 040.
    - **Functions**: `songErrors`, `recordingErrors`, `timingErrors` and
      `contributionErrors`. Each returns every broken rule once, in the server's order.
    - **`ContributionFailure.error`**: reads a failure's code as a `ContributionError`.
  - **`paste_lyrics.dart`**: `splitPastedLyrics(text)`.
    - Blank lines split blocks, and spaces and line endings are tidied.
    - A block equal to an earlier one becomes a repeat in the play order, and that
      earlier block becomes a Chorus.
    - Section IDs follow the kinds: `v1`, `v2`, `c1`.
  - **`youtube.dart`**: `youtubeVideoId(link)`.
    - It reads watch, youtu.be, shorts, embed, live and music.youtube links, with or
      without a scheme or extra parameters.
    - A bare 11-character ID is accepted. Anything else gives null.
  - **`song_slug.dart`**:
    - **`proposeSongSlug(title, {transliteration})`**: it uses the transliteration
      when given. Otherwise Ethiopic words become their consonants, using the search
      code's `consonantSkeleton`. The result is lower case with hyphens, at most 120
      characters, and falls back to `song`.
    - **`newRecordingId()`**: a random lower-case UUID v4.
  - **`contribution_repository.dart`**: the `ContributionRepository` interface, with
    `submit`, `resubmit`, `mine`, `queue` and `review`.
- **`zema_core/lib/src/lyrics/lyrics_models.dart`**: `Recording` gains `youtubeId` and
  `fileName`, matching 041's document keys.
- **`zema_core/lib/src/failures.dart`**: `ContributionFailure(code)`.
- **`zema_data/lib/src/supabase_contribution_repository.dart`**:
  - It calls the RPCs, and reads the user's own rows from `contributions`.
  - A server code the app knows becomes a `ContributionFailure`, including the limit
    and `already_reviewed` codes. `not_signed_in` becomes an `AuthFailure`.
- **`apps/mobile/test/helpers/fake_contributions.dart`**: `FakeContributionRepository`.
  It keeps rows in memory and applies the same rules, the limits, resubmit and review.
- **Tests**:
  - **`zema_core`**: the model round trips, every rule code, paste-split, the YouTube
    parser and slugs.
  - **A parity test**: the codes in the migration headers equal `ContributionError`'s.
  - **`zema_data`** backend tests against the local Supabase:
    - submit, then mine, then the queue, then request changes, then resubmit, then
      reject
    - approving a new song publishes it, and `fileName` is served
    - a rule error, the limit as HTTP 429, and `already_reviewed` as HTTP 409, each
      becoming a `ContributionFailure`
    - a guest gets an `AuthFailure`
  - **The fake**: a unit test.

### Dependencies

- Bolts 039–041 (server functions); 005's `SupabaseAuthRepository.run`, and the local
  backend test support.
- **The local service key**, read at test time from `supabase status`, as the anon key
  is. It's used only by the backend tests, to grant the moderator role and to remove
  the songs and contributions the tests create. It's never printed or committed.

### Deviations from the story

- **No `isModerator` on the contribution repository.** `Profile.isModerator` (005)
  already gives it.

### Acceptance Criteria

- [ ] All four kinds round-trip through `toPayload` and `fromPayload`, in 004's format.
- [ ] Each rule code has a test, and the Dart codes equal the server's.
- [ ] Paste-split, YouTube parsing and slugs are covered, including Windows line
  endings and a chorus pasted three times.
- [ ] The repository works end to end against the local backend, and server errors map
  to typed failures.
- [ ] The fake follows the same rules.
- [ ] Analyze and format are clean. All app, `zema_core` and `zema_data` tests pass.
- [ ] Key scan clean before commit.
