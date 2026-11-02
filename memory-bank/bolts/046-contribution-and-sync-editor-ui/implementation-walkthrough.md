---
stage: implement
bolt: 046-contribution-and-sync-editor-ui
created: 2026-11-02T16:30:00Z
---

## Implementation Walkthrough: contribution-and-sync-editor-ui (bolt 5 of 11)

### Completed Work

- [x] `packages/zema_core/lib/src/contribute/sync_editing.dart`, exported.
- [x] `apps/mobile/lib/features/contribute/data/sync_player.dart`: `SyncPlayer` and
  `JustAudioSyncPlayer`. Positions come every 50–200 ms; taps read the position
  directly.
- [x] `application/recording.dart`: `syncPlayerProvider`, a factory so each S21 gets
  its own player.
- [x] `presentation/sync_step.dart`:
  - **`recordingAudio`**: Zema's copy of a shared file, or the library track through
    a plain DAO query.
  - **`SyncStep`**, with `_PlaybackBar`, `_HoldButton` and `formatSyncTime`.
  - **Start edits apply to the latest draft**, so a held nudge repeats correctly
    between frames.
  - **Loading waits until after the first frame**, because it changes providers.
- [x] `contribute_flow_screen.dart`: the sync step goes to `SyncStep`.
- [x] `app_en.arb`: 13 strings.
- [x] **Test helpers**: `FakeSyncPlayer`, and `pumpZemaApp` gains `syncPlayer`.
