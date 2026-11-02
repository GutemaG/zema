---
stage: implement
bolt: 049-contribution-and-sync-editor-ui
created: 2026-11-02T19:30:00Z
---

## Implementation Walkthrough: contribution-and-sync-editor-ui (bolt 8 of 11)

### Completed Work

- [x] `packages/zema_core/lib/src/contribute/corrections.dart` (new, exported):
  - **`changedLines(base, edited)`** gives `LineChange`s (added, removed,
    changed, with the block id and the old and new line), through a longest
    common subsequence per block.
  - **`songChanged`**: whether a correction changes anything; for S22's
    "no changes, submit disabled".
  - **`recordingsLosingTimings(edited, recordings, timings)`** mirrors
    `publish_contribution`'s `edit_lyrics` branch.
  - **`correctionDraft`, `recordingDraft`, `syncDraft`** build the drafts the
    ways in start.
- [x] `apps/mobile/lib/features/contribute/presentation/start_contribution.dart`
  (new): **`startContribution(context, ref, draft:)`**.
- [x] `apps/mobile/lib/features/contribute/application/contribution_starts.dart`
  (new):
  - `catalogEntryProvider`
  - `newSongDraftFor(track)`
  - `recordingToSync` and `syncableRecordingProvider`
- [x] `lyrics_step.dart`:
  - **`_SimilarSongs`**, with `similarSongDelay`. It's only for new songs.
  - **`_useSimilar`** downloads the song and changes the draft.
  - `didUpdateWidget` refills the fields when the draft becomes a correction.
  - **For a correction**: a note at the top, and Next goes to review.
- [x] `contribute_screen.dart`: Add lyrics calls `startContribution`; `_signedIn`
  is gone.
- [x] `search_screen.dart`: the no-results C07 has the action.
- [x] `lyrics_view.dart`: `NoLyrics` is a `ConsumerWidget` with Add lyrics.
- [x] `song_detail_screen.dart`: the ⋮ menu shows for catalog songs in builds
  with accounts, with the three entries before Report.
- [x] `correction_changes.dart` (new): **`CorrectionChanges(base:, edited:,
  recordings:, timings:)`**. To place it on S22, pass the catalog song
  (`songProvider(draft.songId)`), `draft.song`, and the song's recordings and
  timings (from `lyricsRepositoryProvider`).
- [x] `app_en.arb`: 17 strings at the end.

### Left for later

- **`CorrectionChanges` isn't on S22 yet**, and S22 should disable Submit when
  `songChanged` is false. Bolt 048 writes S22.
- **The flow's title still says "Add lyrics"** for a correction, a recording
  or a sync draft (`contribute_flow_screen.dart` belongs to bolt 048).
- **Sync this recording** covers local-file recordings only (see the plan).
