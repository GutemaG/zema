---
stage: plan
bolt: 049-contribution-and-sync-editor-ui
created: 2026-11-02T19:00:00Z
---

## Implementation Plan: contribution-and-sync-editor-ui (bolt 8 of 11)

### Objective

The similar-song warning, the ways into contributing from where the user is
(story 010), and suggesting a correction (story 011).

### Deliverables

- **"A similar song exists" on S19**: half a second after the title is typed,
  up to three catalog songs with a similar title, from the phone's copy of the
  index (offline too). Each offers:
  - Add a recording: the draft becomes a recording of that song, at S20
  - Suggest a correction: the draft becomes a correction, S19 filled with it
  - an ✕ ("Not the same song") hides them
- **Ways in**, each signing a guest in first (C09):
  - Search with no results: "Add this song's lyrics", the title filled in
  - the "No lyrics" state of a track: "Add lyrics", with title, artist and the
    track already chosen as the recording
  - Song detail's ⋮ menu: Suggest a correction, Link a recording, and Sync
    this recording when the phone plays a recording of the song that has no
    timing
  - none of them in a build without accounts
- **`startContribution`**: one helper for "sign in if needed, start the
  draft, open it"; S05's Add lyrics uses it too.
- **Corrections**: the draft is `edit_lyrics` with the song id and the
  index's version as the base version. S19 says it's a correction, and Next
  goes straight to review.
- **`zema_core`**: `changedLines`, `songChanged`, `recordingsLosingTimings`,
  and `correctionDraft` / `recordingDraft` / `syncDraft`.
- **`CorrectionChanges`**: a widget listing the changed lines and naming the
  recordings that would lose their timings. Not placed on S22 (bolt 048
  writes S22).

### Decisions (recommended options)

- **The base version is the index entry's `version`.** The index is on the
  phone, and `songProvider` downloads the song again whenever that version
  changes, so the lyrics and the version match.
- **Lines are compared block by block** (blocks match by id, which a
  correction keeps), each written line once. A removed line followed by an
  added one is a change. Simple to read, and it's what the moderator sees.
- **`recordingsLosingTimings` takes the timings**, not just the recordings:
  the backend drops every timing whose start count isn't the new sung line
  count, so only timed recordings can lose one.
- **Choosing a similar song replaces what was typed.** It shows right after
  the title, before most typing. The recording, track and shared file chosen
  so far carry over.
- **Sync this recording only for local-file recordings** whose file name
  matches a track linked to the song (the playing one first). The sync editor
  can't play YouTube, and Telegram files live only in their own draft.
- **The track menu (C03) has no Add lyrics.** Its actions run after the menu
  closes, when its `ref` is gone; the No lyrics state is where a missing
  song shows.
