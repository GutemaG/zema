---
stage: plan
bolt: 027-cloud-lyrics-catalog-ui
created: 2026-10-29T12:55:28Z
---

## Implementation Plan: cloud-lyrics-catalog-ui (bolt 6 of 7)

### Objective

Two Should stories:

- **Report wrong lyrics** (story 006, FR-8): a listener can tell the moderators that a
  catalog song's lyrics are wrong, from Song detail or the Now Playing lyrics options.
  Offline, the report waits on the phone and is sent later.
- **Recordings tab** (story 007): Song detail gets a third tab listing the song's
  recordings: artist, source, duration, and Synced or Text only. The recording the
  lyrics view uses is marked.

### Deliverables

#### Reports

- **Install ID**: a random ID (UUID v4 form, from `Random.secure`) created on first
  use and kept in shared_preferences. The server stores it hashed.
- **Drift v5: `QueuedReports`** (id, songId, recordingId?, reason, note?, createdAt),
  with a `ReportsDao`: `add`, `all` (oldest first), `remove(id)`, `watchCount`.
  The migration step is `from4To5`, and the schema is exported for the migration test.
- **`ReportSender`** (`features/catalog/application/report_sender.dart`):
  - **`send(report)`**:
    - It first sends any queued reports.
    - Then it calls `catalog.report(...)`.
    - **Accepted**: `sent`.
    - **`NetworkFailure`**: the report is queued and the result is `queued`.
    - **`RateLimitFailure`**: `limited`. Nothing is queued, since the limit would
      refuse it again today.
    - **Any other failure**: `failed`. The report is refused for good (an unknown
      song, for example), so it isn't queued.
  - **`flush()`** sends the queue oldest first:
    - **Sent**: removed.
    - **Song no longer in the saved index**: dropped quietly, without a network call.
    - **Refused for good** (`BackendFailure`, `LyricsFormatFailure`): dropped.
    - **`NetworkFailure` or `RateLimitFailure`**: it stops and keeps the rest for
      next time.
    - Only one flush runs at a time.
  - It runs at startup (next to the index refresh) and before each new report.
- **Report sheet** (`report_lyrics_sheet.dart`):
  - Four reason radio rows (Wrong words, Wrong timing, Wrong song, Other), none
    selected at first.
  - An optional note field, up to 500 characters with a counter.
  - **Send** is enabled once a reason is picked. While sending it shows a spinner,
    and the sheet closes when the answer comes back.
  - **Snackbars**:
    - sent: "Thanks, we'll take a look"
    - queued: "You're offline, so it'll be sent later"
    - limited: "You've sent the most reports for today. Try again tomorrow."
    - failed: "Couldn't send the report"
- **Where it's offered**: only for songs in the catalog index, in a build with a
  backend.
  - **Song detail**: an overflow menu in the app bar with "Report wrong lyrics".
  - **Now Playing lyrics options**: a "Report wrong lyrics" row at the bottom.
    It closes the options and opens the report sheet with the recording in use.

#### Recordings tab

- **`songRecordingsInfoProvider(songId)`**: each recording with whether it has a
  timing (`repository.timing(id) != null`). Same source as the lyrics view.
- **Song detail**: the tabs become Lyrics · Recordings · Info.
  - **Each row**:
    - title: the artist, or "Unknown artist"
    - subtitle: "source · m:ss" (the duration is left out when unknown)
    - trailing chip: "Synced" or "Text only"
  - **The first recording**, which the lyrics view uses (`trackLyricsProvider` takes
    `firstOrNull`), is marked "Used for lyrics" under the subtitle.
  - **No recordings**: "No recordings yet".
  - At 1.3× text the row wraps and doesn't overflow.

#### Strings

About 20 new strings in `app_en.arb`, with English fallback for am, om and ti.

### Dependencies

- Bolt 019: `submit_report`: 5 a day per install (PT429), and 22023 for bad input.
- `zema_data`: `report()` maps PT429 to `RateLimitFailure` and 22023 to
  `BackendFailure`.
- Bolt 024: `lyricsRepositoryProvider` (recordings and timings, cached offline).

### Technical Approach

- **No connectivity package**: the queue is sent at startup and before each new
  report. The edge case "song removed" is checked against the saved index.
- **The note is trimmed**, and an empty note is sent as null.
- **The used recording is defined once**, in a small `usedRecording(recordings)`
  helper, so the tab and the lyrics view can't drift apart.

### Acceptance Criteria → Tests

| Criterion | Test |
|-----------|------|
| Sheet asks for a reason and optional note, from Song detail and Now Playing | widget tests: menu → sheet; options → sheet; Send off until a reason is picked; 500-char limit |
| Online: thanks snackbar | sender test (catalog called with reason, note, install ID, recording); widget test |
| Offline: queued in Drift, sent later | sender test: queued on NetworkFailure, flushed oldest first at the next send/startup, stops on a network failure |
| Daily limit: friendly message | sender test (not queued); widget test (message) |
| Queued report for a removed song is dropped quietly | sender test |
| Install ID | test: created once, kept |
| Drift v5 | migration test v4 → v5 |
| Recordings: artist, source, duration, Synced/Text only; used one marked; empty state | widget tests |
| 1.3× text, light and dark: no overflow | widget test at 1.3× in both themes |

### Emulator Check

1. Open Galatoomi's Song detail, then Recordings. Expected: rows with Synced or Text
   only, and the first marked.
2. Report it (Wrong words, with a note). Expected: thanks. The row shows in the local
   database.
3. Stop the backend and report again. Expected: "sent later". Start the backend and
   restart the app. Expected: the queued report arrives.
4. Report until the limit. Expected: the friendly message.
