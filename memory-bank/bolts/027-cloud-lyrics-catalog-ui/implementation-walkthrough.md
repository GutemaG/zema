---
stage: implement
bolt: 027-cloud-lyrics-catalog-ui
created: 2026-10-29T13:00:36Z
---

## Implementation Walkthrough: cloud-lyrics-catalog-ui (bolt 6 of 7)

### Summary

- **Report wrong lyrics** is offered for catalog songs, in a build with a backend:
  - from Song detail's overflow menu
  - from the bottom of the Now Playing lyrics options
- **The report sheet** asks for a reason and an optional note. The answer shows in a
  snackbar: thanks, sent later, the daily limit, or couldn't send.
- **Offline**, reports wait in Drift v5. They are sent at app start and before each
  new report.
- **Song detail** gets a Recordings tab, between Lyrics and Info.

### Files

- **`tables.dart`, `zema_database.dart`**
  - New table `QueuedReports`: id, songId, recordingId?, reason (the enum name),
    note?, createdAt.
  - Schema v5, with migration step `from4To5`.
  - The v5 dump is `drift_schemas/zema/drift_schema_v5.json`, made by
    `drift_dev make-migrations`, which also wrote `test/.../generated/schema_v5.dart`.
- **`reports_dao.dart`** (new)
  - **`LyricsReport`**: songId, recordingId?, reason, note?.
  - **`ReportsDao`**: `add`, `all` (oldest first; an unknown reason reads as Other)
    and `remove`.
- **`features/catalog/application/report_sender.dart`** (new)
  - **`installId(preferences)`**: 32 hex characters from `Random.secure`, kept
    under `catalog.installId`. The server needs 8–64 characters and stores only a
    hash.
  - **`ReportSender.send`**:
    - It flushes the queue first, then reports.
    - What happens next:
      - **Accepted**: `sent`.
      - **`NetworkFailure`**: the report is queued, and the result is `queued`.
      - **`RateLimitFailure`**: `limited`, and nothing is queued.
      - **Any other `ZemaFailure`**: `failed`, and nothing is queued.
      - **No backend**: `failed`.
  - **`flush()`**: oldest first.
    - A report whose song isn't in the saved index is dropped without a network
      call.
    - A report refused for good is dropped.
    - On `NetworkFailure` or `RateLimitFailure` it stops and keeps the rest.
    - A second call while one runs shares it.
  - **`reportStartupFlushProvider`**: listened to by the app shell, next to the
    index refresh.
  - **`canReportProvider(songId)`**: true when there is a backend and the song is in
    the index.
- **`lyrics/presentation/report_lyrics_sheet.dart`** (new)
  - Four reasons in a `RadioGroup`, none picked at first.
  - A note field of at most 500 characters (enforced, with a counter). It is trimmed,
    and an empty note is sent as null.
  - Cancel and Send.
    - Send is off until a reason is picked.
    - While sending it shows a spinner, and the reasons, the note and Cancel are
      locked.
    - The sheet closes when the answer comes back, and the snackbar shows on the
      screen underneath.
- **`lyrics_options_sheet.dart`**
  - A "Report wrong lyrics" row when the song can be reported.
  - It pops the options with `true`. `showLyricsOptionsSheet` then opens the report
    sheet with the song and the recording in use, so the two sheets never stack.
- **`track_lyrics.dart`**
  - **`usedRecording(recordings)`**: the first recording. The lyrics view and the
    Recordings tab both use it.
  - **`songRecordingsInfoProvider(songId)`**: each recording with
    `synced = timing != null`.
    - It waits on `songProvider`, so the lyrics C07's Try again also retries it.
    - Riverpod's automatic retry is off, as for the other lyrics providers.
- **`song_detail_screen.dart`**
  - Three tabs.
  - An overflow menu with Report wrong lyrics, shown only when the song can be
    reported.
  - **`_RecordingsTab`**:
    - Each row: the artist (or "Unknown artist") as the title.
    - The subtitle: "source · m:ss", and "Used for lyrics" on the first recording.
    - On the right: "Synced" in the accent colour, or "Text only" in muted.
    - "No recordings yet" when there are none.
    - The C07 panel when loading fails.
  - The source names moved into a file-level `_sourceName`, shared with Info.
- **`app_en.arb`**: 18 strings. am, om and ti fall back to English.

### Change From the Plan

- **The plan**: the plan counted on the server's code 22023 for "refused for good".
- **What was built**: any `ZemaFailure` other than `NetworkFailure` and
  `RateLimitFailure` counts as refused for good.
- **Why**: `zema_data` maps 22023 to a `BackendFailure`, but it also gives one for a
  refused key, and the code isn't visible to the app. Retrying either would never
  succeed, so dropping both is the same outcome.

### Checked

- `flutter analyze` is clean, and `dart format` is applied.
- **App: 750 tests pass.** The 2 that fail are in `schema_test`, which still expects
  v4 and ten tables. They will be updated in stage 3.

### Notes

Stage 3 covers:

- the v4 → v5 migration and the schema test
- the DAO
- the install ID
- the sender: send outcomes, queueing, flush order and drops, stopping, and shared
  flushes
- widget tests for the sheet from both places
- the Recordings tab, including 1.3× text in light and dark
- the emulator check against the local backend
