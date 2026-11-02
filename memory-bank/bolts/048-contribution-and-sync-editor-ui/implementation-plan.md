---
stage: plan
bolt: 048-contribution-and-sync-editor-ui
created: 2026-11-02T19:00:00Z
---

## Implementation Plan: contribution-and-sync-editor-ui (bolt 7 of 11)

### Objective

Review & submit (S22) and the contributor's own copy (story 009).

### Deliverables

- **S22, the review step**: song details, the lyrics in play order, the
  recording, and the sync status (Synced / Text only / YouTube — not synced),
  each part with Edit. A "Submit for review" button like `07d`'s.
- **Submit**:
  - the rules run again on the phone first
  - one contribution goes through `ContributionRepository.submit`
  - progress while sending; a second tap does nothing
  - success: a message, back to S05, the draft deleted
  - a failure (offline, server error, a limit, a broken rule): the draft is
    kept, a message names the problem, and Submit works again
- **The own copy**: a Drift table (schema v9) holding what was sent with the
  contribution id, the local track and Zema's copy of a shared file.
- **Pending lyrics**: a track with an own copy shows its lyrics and timings,
  marked "Pending review", on this phone only.
- **Reconcile**: `OwnCopyReconciler.reconcile(mine)` for bolt 050:
  approved links the track to the catalog song and removes the copy; rejected
  removes the copy. Either way the shared file goes.
- **Sign-out and account deletion** clear the own copies and their files.
- **`zema_core`**: the limits `maxOpenContributions` (20) and
  `maxContributionsPerDay` (30).

### Decisions (recommended options)

- **No "My contributions" link yet.** That screen is story 012. Success shows
  a message and goes back to S05; 012 can add the link to the same message.
- **An own copy is kept for every contribution**, with or without a track,
  so the shared file's path stays with it until the review.
- **The own copy comes before the linked song** in `trackLyricsProvider`, and
  the newest copy wins when a track has several.
- **Approval sets a manual link** to the catalog song, so automatic matching
  keeps it. Rejection leaves the link alone, so the track goes back to what
  it had.
- **Failures show in a box above Submit**, not a snack bar, so the message
  stays while the user decides what to do.
- **The contribution repository provider** lives with the other account
  repositories (`account_providers.dart`), null without a backend.
