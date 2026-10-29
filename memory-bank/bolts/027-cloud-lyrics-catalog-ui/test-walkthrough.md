---
stage: test
bolt: 027-cloud-lyrics-catalog-ui
created: 2026-10-29T13:23:54Z
---

## Test Walkthrough: cloud-lyrics-catalog-ui (bolt 6 of 7)

### Results

- **App: 789 tests pass**, 41 of them new. The other suites pass too: `zema_core` 201
  and `zema_data` 28.
- `flutter analyze` is clean and `dart format` changes nothing.
- The iOS simulator build passes.

### New Tests

- **`schema_test`** now checks for v5 and eleven tables, including
  `queued_reports`.
- **`migration_test`**
  - v4 → v5 keeps the index and the cache, and starts an empty queue.
  - The generated simple-migration tests now also cover 1–4 → 5 (+4).
- **`reports_dao_test`** (3): oldest first with every field; `remove`; an unknown
  reason reads as Other.
- **`report_sender_test`** (18)
  - **Install ID**: 32 hex characters, made once and kept; different between
    installs.
  - **`send` results**:
    - sent: with the reason, note, recording and install ID
    - offline: queued
    - daily limit: limited, nothing queued
    - refused: failed, nothing queued
    - no backend: failed
  - **`send` and the queue**: the queue is sent before the new report, and offline
    the new report joins the end of it.
  - **`flush`**:
    - sends oldest first
    - drops a report whose song left the index, with no network call
    - drops a refused report and sends the rest
    - offline, stops and keeps everything
    - at the daily limit, keeps the refused report and the rest
    - shares a second flush that starts while one runs
  - **`canReportProvider`**: true for a song in the index; false for one that isn't,
    and false with no backend.
- **`report_and_recordings_test`** (14, widget)
  - **The report sheet from Song detail**:
    - shows the four reasons and the note field, with Send off until a reason is
      picked
    - online: the thank-you, and the note trimmed
    - a blank note is sent as none
    - offline: queued
    - limit: the message, nothing queued
    - refused: the message
    - while sending: a spinner, with Send and Cancel locked
    - Cancel sends nothing
    - the note stops at 500 characters with a counter
    - a build with no backend has no menu
  - **Recordings**:
    - each row shows its artist, source, duration and Synced or Text only
    - only the used recording is marked, and it is listed first
    - a song with no recordings shows the empty state
    - 1.3× text, light and dark: a long artist name doesn't overflow
- **`lyrics_view_test`** (+1): Report in the Now Playing options closes them and opens
  the report sheet. The report carries the song and the recording in use.

### Planted Bugs

- **29 planted bugs, 28 caught on the first run.**
- **The miss**: making the lyrics view use the *last* recording failed no test.
  - The cause: the Recordings tab marked the first row (`i == 0`), not the
    recording `usedRecording` returns. So the tab and the lyrics view could
    disagree, which the plan said the shared helper would prevent.
  - **Fixed**: the tab now marks the recording `usedRecording` picks, and the same
    planted bug is now caught.
  - A follow-up bug, "mark the first row instead", fails no test. It is equivalent
    to the code while `usedRecording` picks the first.

### Emulator Check (Android, local backend)

1. **Galatoomi → Recordings**: "Zema Samples · Bundled sample · 0:43", marked "Used for
   lyrics", with a Synced badge.
   - The first build showed the label and badge in the plain text colour. They now
     use `accentText` on `soft`, the design system's Synced badge.
2. **Report from the menu, online** (Wrong words, with a note): the thank-you
   showed.
   - The server row has the reason, the trimmed note and a 64-character install
     hash.
   - Closing the sheet with Back sent nothing.
3. **Offline**, with the gateway container paused, from **Now Playing → Lyrics
   options → Report**:
   - The options closed and only the report sheet opened.
   - While sending it showed the spinner, then "You're offline, so it'll be sent
     later".
   - The phone's `queued_reports` held the report with recording `galatoomi`.
   - After unpausing and restarting the app, it reached the server within 1 s, and
     the queue was empty.
4. **The daily limit**: the friendly message showed once the server had 5 reports
   from this install.

### Finding: A Report That Times Out Can Arrive Twice

In step 3 the offline report reached the server anyway: the row is timed 13:20:35,
while the gateway was paused. The app had already timed out and queued it, so the
startup flush sent it again (13:20:49).

- **Why**: a timeout doesn't prove the request was lost.
- **Effect**: a duplicate report for moderators, and one of the day's 5 reports used
  up. That's why the 4th report sent in step 4 was refused.
- **What would fix it**: the app generates a report ID and `submit_report` ignores a
  repeat of it. That's a backend change (a new column with a unique constraint, plus
  the function), so it isn't made in this bolt.

### Still Open

- **Duplicate reports after a timeout**: see the finding above.
- **No network watcher**: queued reports wait for the next app start or the next
  report.
- **Failing widget tests can still hang a run**, as in earlier bolts. One run hung
  here after its failures.
