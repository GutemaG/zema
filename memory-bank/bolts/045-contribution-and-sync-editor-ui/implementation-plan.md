---
stage: plan
bolt: 045-contribution-and-sync-editor-ui
created: 2026-11-02T15:20:00Z
---

## Implementation Plan: contribution-and-sync-editor-ui (bolt 4 of 11)

### Objective

S20 "Link a recording" (story 005) and Telegram share on Android (story 006).

### Deliverables

- **`RecordingStep`**, with three choices:
  - **A song on this phone**: a searchable picker; the track that opened the flow is
    marked.
  - **A YouTube link**: parsed with `youtubeVideoId`; oEmbed gives the title and
    thumbnail; a length can be typed (m:ss).
  - **An audio from Telegram**: the shared file, or how to share one.
- **An artist field**, filled in from the track's artist or the channel name.
- **The buttons**:
  - **Back**, and the step strip's earlier steps.
  - **Skip** (new songs only), which goes to review with no recording.
  - **Next**: to sync, or to review for YouTube, with the explanation shown. If the
    lyrics still have problems, it goes back to them.
- **Telegram share**:
  - an `audio/*` SEND intent filter, and `ShareChannel.kt`, which copies the file into
    `files/shared_audio` and reads its name and duration
  - `AndroidShareReceiver` in Dart
  - `AppShell` opens a new draft at S20 with the file, after C09 for a guest
- **Clean-up**: the copied file is deleted with its draft, on sign-out, when a guest
  says Not now, and when there's no backend.
- **`zema_core`**:
  - `ContributionDraft` gains `audioPath` and `videoTitle`
  - `parseDurationText` and `formatDurationText`

### Decisions (recommended options)

- **Our own platform channel, not `receive_sharing_intent` or `share_handler`** (the
  story suggested one of those).
  - It's about 130 lines of Kotlin, next to the existing `LibraryChannel`.
  - The copy happens natively while the sharing app's permission is still valid.
  - There's no plugin to keep up to date.
- **The oEmbed result and thumbnail are kept in `support/youtube/<id>`**, like avatars.
  Offline, the video id is kept and the title is typed.
- **Steps 3 and 4 show a "coming in the next update" line** until bolts 046–048.
- **Deleting the copy after approval or rejection** needs contribution status, which
  arrives in bolt 050. It's noted there.
