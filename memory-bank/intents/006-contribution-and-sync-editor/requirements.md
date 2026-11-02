---
intent: 006-contribution-and-sync-editor
phase: inception
status: units-defined
created: 2026-10-23T22:16:40Z
updated: 2026-11-02T07:00:52Z
---

# Requirements: Contribution and Sync Editor

> Source: `docs/roadmap.md` Stage 6 · screens: `docs/screens.md` S05, S07, S09, S19–S23,
> S23m · designs: `design/screens/*/05-contribute.png`, `06-add-lyrics.png`,
> `07a-sync-list.png`, `07b-sync-focus.png` · Complexity ★★★★☆ · Needs backend; small
> native piece (Android share intent).

## Intent Overview

Signed-in users add lyrics, suggest corrections, link recordings and sync line timings.
Moderators approve, request changes or reject. Only approved content becomes public, and
from then on every phone downloads it like any other catalog song (intent 004).

The intent has three parts:

- **Contributing** (the four-step flow S19 → S22, corrections, S09, drafts).
- **Following a contribution** (S23 My contributions and the in-app status badge).
- **Moderation** (S23m in the app, and the server rules that publish approved content).

## Business Goals

| Goal | Success Metric | Priority |
|------|----------------|----------|
| Community-grown catalog | A user submits lyrics and sync for a local song; a moderator approves; a second phone with the same song sees the synced lyrics | Must |
| Quality control | No contributed content is publicly readable before a moderator approves it | Must |
| Contributors stay informed | A contributor sees each status change (approved, needs changes, rejected) the next time they open the app | Must |

---

## Decisions (resolved 2026-11-02)

| Question | Decision |
|----------|----------|
| Sync editor design (roadmap open decision #1) | **7a list with a toggle to 7b focus.** No step or line counters in either view. |
| How moderators are chosen (roadmap open decision #4) | **The owner grants the role by a server-side script** with the person's email. Nothing in the app grants roles. The admin website (008) adds a screen later. |
| Syncing a YouTube recording | **Link only, no sync.** Syncing needs audio the phone can play: a local file or a Telegram audio. |
| Status change notifications | **In-app badge**, checked when the app opens or resumes. No push. |
| Optional scope | All included: Telegram share, S09 Edit song info, corrections to existing songs, status notifications. |

---

## Functional Requirements

### FR-1: Contribute tab (S05) and entry points

- **Description**: The Contribute tab replaces its "Coming soon" message with S05 "How it
  works" (design `05-contribute.png`): the steps, "Add lyrics", the user's drafts, and a
  link to My contributions.
- **Acceptance Criteria**:
  - Guests see the tab's explanation, and every action opens C09 (from 005) with a
    contributing reason. After sign-in, the action continues.
  - **Entry points** (all require sign-in through C09):
    - Contribute tab → "Add lyrics" (S19).
    - Search with no results → "Add this song's lyrics" (S19, title prefilled).
    - Song detail (S07) → "Link a recording" (S20 for that song).
    - Song detail → "Sync this recording" when the playing local file has a recording
      without timings (S21).
    - Song detail → "Suggest a correction" for catalog songs (FR-8).
    - A track with no lyrics → "Add lyrics" (S19, title, artist and track prefilled).
  - Builds without a backend hide the Contribute actions, like other catalog features.
- **Priority**: Must

### FR-2: Add lyrics (S19, step 1 of 4)

- **Description**: Song details and the lyrics in blocks, with the play order (design
  `06-add-lyrics.png`).
- **Acceptance Criteria**:
  - **Fields**: title (required), transliteration (optional), artist, album (optional).
  - **Duplicate check** while typing the title (catalog search from 004, after a short
    pause): "A similar song exists" with the matches. Choosing one switches to adding a
    recording to it (S20) or suggesting a correction (FR-8). The user can ignore it.
  - **Block editor**: block type (Verse / Chorus / Bridge / Other) and its lines; add,
    delete and reorder blocks and lines; an optional transliteration per line.
  - **Play order strip**: the order the blocks are sung in, as references, so a chorus
    is written once and repeated. Add, remove and reorder entries. By default each block
    appears once, in order.
  - **"Paste all text"** splits pasted text into blocks: a blank line starts a block; a
    block identical to an earlier one becomes a repeat of it in the play order, and that
    block is marked Chorus. The user can change the result.
  - Next is enabled only when FR-11's lyrics rules pass; errors are shown on the field.
- **Priority**: Must

### FR-3: Link recording (S20, step 2 of 4)

- **Description**: Which performance the timings belong to. Also opens from Song detail
  to add another recording to an existing song.
- **Acceptance Criteria**:
  - **Local file**: picked from the library (S18-style list with search). The track's
    duration and file name are kept. A track already open in the flow is preselected.
  - **Telegram audio** (Android): the user shares an audio file from Telegram (or any
    app) to Zema. Zema copies it into its own storage, adds it as a playable source for
    this contribution, and opens the flow at S20 with it selected. iOS has no share
    target in this intent.
  - **YouTube link**: the app takes the video ID from any common link form (watch,
    youtu.be, shorts, music.youtube). It fetches the title and thumbnail without an API
    key (oEmbed). Duration is optional and can be typed. A YouTube recording can't be
    synced, and S21 is skipped with an explanation.
  - **Artist / choir name** for the recording (prefilled from the track's artist).
  - The step is optional for a new song: lyrics can be submitted with no recording.
  - Audio files are never uploaded. Only the source type, the video ID or file name,
    the artist and the duration are sent.
- **Priority**: Must (Telegram share: Should)

### FR-4: Sync editor (S21, step 3 of 4)

- **Description**: Tap along with the recording to time each line occurrence. Two views
  of the same timings: **List** (design 7a, the default) and **Focus** (design 7b), with
  a button in the app bar to switch.
- **Acceptance Criteria**:
  - **List view**: playback bar (play/pause, position and duration, −5 s, speed 0.75× /
    1×), every line occurrence in play order with its time or "—", the current line
    highlighted with "Tap when this line starts", "Undo last tap", and a large
    "Tap — next line" button.
  - **Focus view**: the previous line (with its time), the current line large with its
    block type, the next line, a large tap area, and Undo / Pause / −5 s.
  - Neither view shows step counters ("Step 3 of 4") or line counters ("3 of 8 lines
    timed", "Line 4 of 8"), and Focus has no progress segments.
  - **Chorus repeats**: each occurrence in the play order is its own row with its own
    time.
  - **Fixing**: in List view, tapping a timed line selects it; hold the nudge control to
    move it ±0.1 s, or "Redo from here" to clear it and the lines after it and play from
    a little before. Times must stay strictly increasing (FR-11); a nudge never passes a
    neighbour.
  - **Preview** plays from the start with the lyrics highlighting as in Now Playing
    (shared lyrics view, C06).
  - The editor plays only this contribution's local or Telegram audio, separately from
    the main player, which is paused while the editor is open.
  - **Optional**: "Skip — submit text only". Timings can be added later from Song detail
    (FR-1).
  - Progress is saved in the draft after every tap (FR-6).
- **Priority**: Must

### FR-5: Review & submit (S22, step 4 of 4)

- **Description**: A summary and the submit action.
- **Acceptance Criteria**:
  - Shows the song details, the lyrics in play order, the recording and the sync status
    ("Synced", "Text only", or "YouTube — not synced"). Each part has Edit, which opens
    its step.
  - Submit runs FR-11's rules again, then sends one contribution to the server.
  - Offline, or on a server error, the draft is kept and a message says so; Submit can
    be tried again.
  - On success: a message with a link to My contributions; the draft becomes a pending
    contribution; and a local copy is used right away for the linked track on this phone
    (FR-7).
- **Priority**: Must

### FR-6: Drafts

- **Description**: Work in progress is saved on the phone.
- **Acceptance Criteria**:
  - Every change in S19–S22 is saved to the local database within a second, and nothing
    is lost when the app is killed.
  - S05 lists drafts (title, last changed, step). Opening one continues at its step;
    drafts can be deleted with confirmation.
  - Drafts stay on this phone only. They aren't backed up, and they're deleted on sign-out
    only after a warning that names them.
- **Priority**: Must

### FR-7: The contributor's own copy

- **Description**: The contributor sees what they submitted before it's approved.
- **Acceptance Criteria**:
  - A pending (or needs-changes) contribution linked to a local track shows its lyrics and
    timings for that track on this phone, marked "Pending review".
  - When it's approved, the catalog version replaces the local copy. When it's rejected,
    the local copy is removed and the track goes back to what it had before.
  - Other phones never see pending content.
- **Priority**: Must

### FR-8: Corrections to existing songs

- **Description**: From Song detail, a signed-in user suggests changes to an approved
  catalog song's text.
- **Acceptance Criteria**:
  - Opens S19 filled with the current song (details, blocks, play order). The submission
    is an "edit lyrics" contribution against that song and the version it was based on.
  - Before submitting, the user sees which lines changed.
  - **Timings**: if the number of line occurrences stays the same, existing timings are
    kept. If it changes, the contributor and moderator are told which recordings will
    lose their timings, and approval removes those timings (the lyrics show as text until
    someone syncs again).
  - If the song changed on the server after the user started, the moderator sees that
    the correction was based on an older version.
- **Priority**: Must

### FR-9: My contributions (S23) and status badge

- **Description**: The user's submissions and their review status.
- **Acceptance Criteria**:
  - Opened from S05 and from Profile (the link 005 left out).
  - Tabs: Pending / Approved / Needs changes / Rejected. A card shows the song, the type
    (new song, correction, recording, sync), the date, and the moderator's comment or
    reason.
  - "Edit" on Needs changes reopens the flow with the submitted data and resubmits the
    same contribution as pending.
  - **Badge**: when the app opens or resumes (online, signed in), it checks for status
    changes since the last check. Changes show a badge on Profile and on S05's My
    contributions link, and one message per change. Opening S23 clears the badge.
  - Profile shows the stats 005 left out: lyrics added, synced, approved.
- **Priority**: Must

### FR-10: Moderator review queue (S23m)

- **Description**: In-app moderation until the admin website (008) exists.
- **Acceptance Criteria**:
  - Visible only to users with the moderator role (from S05 and Profile); the role badge
    from 005 shows "Moderator".
  - **Queue**: pending contributions, oldest first, filtered by type, with the count.
  - **Detail**:
    - a new song: the full lyrics
    - a correction: a line-by-line diff against the current version, and any timings
      that will be removed
    - a recording: the source; a YouTube link opens in the YouTube app
    - sync: a preview that plays the lyrics with highlighting against the timings,
      without the audio, since the moderator may not have the file
    - a checklist (words right, blocks and play order right, not a duplicate, timings
      look right)
  - **Actions**: Approve; Request changes (comment required); Reject (reason required).
  - A moderator can't review their own contribution.
  - If two moderators act on the same item, the second gets "Already reviewed" and nothing
    changes.
- **Priority**: Must

### FR-11: Shared validation (`zema_core`)

- **Description**: One set of rules, used by the app and matched by the server.
- **Acceptance Criteria**:
  - Title required (1–200 characters, trimmed).
  - At least one block, each with at least one non-empty line; at most 300 lines.
  - The play order is non-empty and refers only to existing blocks.
  - Timings: one per line occurrence in the play order, non-negative and strictly
    increasing, and within the recording's duration when it's known.
  - A YouTube video ID is 11 characters of `A–Z a–z 0–9 _ -`.
  - Unit tested in `zema_core`; the server checks the same rules on submit (FR-13).
- **Priority**: Must

### FR-12: Edit song info (S09)

- **Description**: Fix a local file's details without changing the file.
- **Acceptance Criteria**:
  - From Song detail's overflow and the track menu: title, artist, album, track number
    and cover art (from a picked image).
  - Saved in Zema's database as overrides. The file itself is never written.
  - The overrides are used everywhere the track is shown and sorted, in search, and for
    lyrics matching (004).
  - "Reset to file's info" removes them.
  - The overrides are included in the backup (a new backup section, keeping older backups
    readable). Backup track identity keeps using the file's own tags and file name, so
    matching on another phone isn't affected.
- **Priority**: Should

### FR-13: Server: contributions, moderation and publishing

- **Description**: New and changed tables, policies and functions.
- **Acceptance Criteria**:
  - **Submitting**: an RPC creates a contribution for the signed-in user, after checking
    FR-11's rules and the limits (NFR). Kinds: new song, edit lyrics, recording (new),
    sync timing. Users can read only their own contributions and can't change their
    status.
  - **Resubmitting**: the author can update their own contribution only while it's
    "changes requested", which sets it back to pending.
  - **Reviewing**: an RPC that only moderators can call sets approved, changes requested
    (comment required) or rejected (reason required), with the reviewer and time. It
    fails for the reviewer's own contribution and for an already reviewed one.
  - **Publishing on approval**, in the same transaction:
    - a new song: an approved song with its blocks, play order, recording and timings
    - a correction: the song's text replaced and its version bumped, so phones refresh
      it (004); affected timings removed as in FR-8
    - a recording or sync: added to the song
    - recordings store the source reference (video ID for YouTube; file name for local
      and Telegram) and the duration
  - **Moderator role**: a server-side script (run by the owner with the service key, never
    in the app or repo) grants or removes the moderator role by email. The app reads the
    role only.
  - Covered by pgTAP tests: RLS, limits, the role can't be self-granted, only moderators
    review, no self-review, nothing public before approval, and publishing for each kind.
- **Priority**: Must

### FR-14: Backup additions

- **Description**: Data from this intent that the 005 backup should carry.
- **Acceptance Criteria**:
  - The per-recording sync offset (from 003) and S09's overrides are added as new backup
    sections; older apps ignore them and older backups still restore.
- **Priority**: Could

---

## Non-Functional Requirements

### Security and Authorization

| Requirement | Standard | Notes |
|-------------|----------|-------|
| Contributors | RLS | Write only through the submit/resubmit RPCs; read only their own contributions |
| Moderators | RLS + role check in RPC | Only `moderator` (or `admin`) can review; no self-review |
| Public reads | Existing 004 rules | Only approved songs are readable; pending content never is |
| Role changes | Server only | Granted by the owner's script; no API path changes roles |
| Keys | Project rules | Only the public anon key in the app; no service key in the app or repo |

### Abuse limits

| Requirement | Metric | Target |
|-------------|--------|--------|
| Pending contributions per user | Count | At most 20 at a time |
| Submissions per user | Rate | At most 30 per day |
| Contribution size | Payload | At most 256 KB |

### Usability

| Requirement | Metric | Target |
|-------------|--------|--------|
| Sync accuracy from the tap editor | Typical offset after nudging | ≤ ±0.3 s |
| Tap latency | Time from tap to recorded position | Within 50 ms of the audio position |
| Draft safety | Data lost when the app is killed | None (saved within 1 s) |
| Fit | Small phone, 1.3× text, dark and light | No overflow on S05, S19–S23, S23m, S09 |
| Languages | New strings | In the ARB files for English, Amharic, Afaan Oromoo and Tigrinya |

### Reliability

| Requirement | Metric | Target |
|-------------|--------|--------|
| Approval | Atomicity | Publishing is all or nothing; a failure leaves the contribution pending |
| Resubmit/review races | Outcome | One wins; the other is told, nothing is duplicated |

---

## Constraints

### Technical Constraints

**Project-wide standards**: Required standards will be loaded from memory-bank standards
folder by Construction Agent.

**Intent-specific constraints**:
- Requires sign-in (005). Guests get C09 for every contributing action.
- No in-app video playback. YouTube metadata comes from oEmbed, with no API key.
- Audio files are never uploaded to the server.
- The sync editor's player is separate from the main player (just_audio), and the main
  player is paused while it's open.
- The moderator script uses the service key locally and is never committed with a key.

### Business Constraints
- The admin website comes in 008. Until then moderation happens in the app.

---

## Out of Scope

- Push notifications (the in-app badge only).
- Syncing YouTube recordings (stage 7/9 may add a way).
- A Telegram share target on iOS.
- Uploading or hosting audio.
- Granting roles from the app.

---

## Assumptions

| Assumption | Risk if Invalid | Mitigation |
|------------|-----------------|------------|
| YouTube oEmbed gives the title and thumbnail without a key | Lookup fails | Save the video ID and let the user type the title |
| Telegram can share audio files to other apps on Android | Can't link Telegram audio this way | Save to the phone, then pick it as a local file |
| Tapping gives ±0.3 s after a nudge | Poor timings | Speed 0.75×, nudge, and Redo from here; moderators check in preview |
| A second phone with the same file matches the approved song through 004's matching | The other phone doesn't show it | The recording keeps the file name and duration; the user can link it by hand (003) |

---

## Open Questions

None. The roadmap's open decisions #1 and #4 were resolved on 2026-11-02 (see Decisions).
