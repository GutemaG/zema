---
stage: implement
bolt: 045-contribution-and-sync-editor-ui
created: 2026-11-02T15:40:00Z
---

## Implementation Walkthrough: contribution-and-sync-editor-ui (bolt 4 of 11)

### Completed Work

- [x] **`zema_core`**:
  - `contribution_draft.dart`: `audioPath` and `videoTitle`, with JSON, `copyWith` and
    equality.
  - `duration_text.dart`: new.
- [x] **`apps/mobile/lib/features/contribute/`**:
  - `data/youtube_info.dart`: `YoutubeInfoService` and `OEmbedYoutubeInfoService`.
  - `data/shared_audio.dart`: `SharedAudio`, `ShareReceiver`, `AndroidShareReceiver`,
    `NoShareReceiver` and `deleteSharedAudio`.
  - `application/recording.dart`: the service providers, `youtubeInfoProvider`,
    `incomingSharesProvider` and `startSharedDraft`.
  - `presentation/recording_step.dart`: S20, with `_Choice`, `_VideoInfo` and
    `_TrackPicker`.
  - `contribute_flow_screen.dart`: shows the step for the draft's step. The step strip
    goes back when an earlier step is tapped.
  - `application/drafts.dart`: `deleteDraft` also deletes the shared copy.
- [x] **`app_shell.dart`**: listens for shares (C09 first; with no backend, a message).
- [x] **`profile.dart`**: sign-out and account deletion delete the shared copies.
- [x] **`drafts_dao.dart`**: `audioPaths()`.
- [x] **Android**:
  - `ShareChannel.kt`
  - `MainActivity.kt`: the share channel, and `onNewIntent`
  - the manifest's SEND `audio/*` filter
- [x] **`app_en.arb`**: 24 strings.
- [x] **Test helpers**: `fake_contribute.dart`, and `pumpZemaApp` gains `youtube` and
  `shareReceiver`.
