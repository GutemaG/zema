# Zema — Screens, Functions & Features

Inventory of every screen and shared component, used as input for specsmd inception
(intents → requirements → stories). Visual design comes from Google Stitch
(`docs/zema-stitch-prompts.md`, section numbers shown as "Stitch §N").

**Priority:** **P1** = first release (MVP) · **P2** = second release · **P3** = later.
**Platform:** everything works on Android. iOS supports only the in-app player and lyrics
(no detection of other apps, no floating overlay).

---

## Navigation map

```
Onboarding (first run only)
  Welcome → How it works → Permissions → Account choice
                                                │
Main app (bottom navigation + mini player) ◄────┘
├── Home
├── Search ──────────────► Song detail ──► Now Playing
├── Library
│   ├── Tracks
│   ├── Folders ─────────► Folder contents
│   ├── Albums ──────────► Album detail
│   ├── Artists ─────────► Artist detail
│   ├── Favorites
│   └── Playlists ───────► Playlist detail ──► Add songs
└── Contribute
    ├── Add lyrics → Link recording → Tap-to-sync → Submit
    ├── My contributions
    └── Review queue (moderators only)

Profile / Settings (from avatar on Home)
├── Sign in (Google) → Restore backup
├── Backup & sync
├── Floating lyrics & detection settings
└── Settings

Outside the app (Android only)
└── Floating lyrics overlay  (opened by background detection)
```

---

## 1. Onboarding

### S01 — Welcome · P1 · Stitch §1
**Purpose:** first impression and language choice.
- App logo, name, tagline.
- Language selector: English, አማርኛ, Afaan Oromoo, ትግርኛ (each in its own language).
  Changes the UI language immediately and is saved.
- "Get started" → S02.
- Shown only on first launch (or after app data is cleared).

### S02 — How it works · P1 · Stitch §1
**Purpose:** explain the core idea in 3 steps.
- Step illustrations: play on YouTube / Telegram / your files → Zema recognizes the
  song → floating lyrics appear.
- Next / Skip.

### S03 — Permissions setup · P1 · Stitch §1
**Purpose:** get the permissions that power detection, overlay and the local library.
- Three permission cards, each with explanation and live status (Granted / Allow):
  - **Music & audio files** — scan and play local music (`READ_MEDIA_AUDIO`).
  - **Notification access** — read what other apps are playing (notification listener).
  - **Display over other apps** — show floating lyrics (`SYSTEM_ALERT_WINDOW`).
- "Allow" opens the system dialog or the system settings page; status refreshes when the
  user returns.
- Privacy note: only song title / artist / position are read, never messages.
- "Skip for now": the app works with reduced features; missing permissions can be
  granted later from S27 or S28.
- iOS: only the music library permission is shown.

### S04 — Account choice · P1 · Stitch §1
**Purpose:** let users start without an account.
- "Continue as guest" (default) → Home.
- "Sign in" → S24.
- Explains what an account adds: contributing lyrics, backup, restore on a new phone.

---

## 2. Home & search

### S05 — Home · P1 · Stitch §2
**Purpose:** fast access to what the user is listening to now and recently.
- **Now detected card** (Android): appears when a song is detected in YouTube /
  Telegram / another app. Shows source badge, title, artist, progress. Actions:
  "Show floating lyrics", "Open lyrics" (→ S08). Hidden when nothing is detected.
- **Quick actions:** Shuffle all, Favorites, Recently added, Playlists.
- **Continue listening:** last played local tracks with resume position.
- **Recently played:** local and detected songs, with source icon.
- **Your playlists:** horizontal list → S17.
- **New lyrics from the community** (P2): recently approved lyrics; badge
  "Synced" / "Text only".
- Header: search shortcut (→ S06), profile avatar or guest icon (→ S25).
- Empty state for new users with no music: prompt to grant music permission or rescan.

### S06 — Search · P1 · Stitch §3
**Purpose:** find any song, artist, album or lyric line.
- One search field; works with any keyboard. Matching is normalized:
  - Ethiopic letter variants treated as equal (ሀ/ሐ/ኀ, ሰ/ሠ, አ/ዐ, ጸ/ፀ …).
  - Latin transliteration matches Ethiopic text ("kidist" → "ቅድስት").
  - Case, punctuation and extra words ("Official Video", years) ignored.
- Scope chips: All, Songs, Artists, Albums, Lyrics (search inside lyric text),
  On this device.
- Results grouped by type; each song row has favorite toggle and song menu (C03).
- Searches both the local library and the cloud lyrics catalog (cloud results need
  network; local works offline).
- Recent searches (clearable) and popular songs when the field is empty.
- No results: "Add this song's lyrics" → S19 (P2).

### S07 — Song detail · P1 · Stitch §4
**Purpose:** everything about one song.
- Header: art, title, transliteration, artist, album. Actions: Play, favorite,
  add to playlist (C04), share.
- **Lyrics tab:** structured lyrics — verses, chorus blocks with "↻ repeat" markers;
  font size A−/A+. Shows "No lyrics yet" + "Add lyrics" (P2) when missing.
- **Recordings tab** (P2): versions by different artists, each with source (YouTube /
  Telegram / Local), duration, sync status, play/open. "Link a recording" → S20.
- **Info tab:** album, artist, contributors, approval status, last updated.
- Report wrong lyrics (P2).

---

## 3. Player

### S08 — Now Playing · P1 · Stitch §5
**Purpose:** listen with synchronized lyrics.
- Synced lyrics: current line highlighted and auto-scrolled; past dimmed; tap a line to
  seek. Falls back to plain text when the recording has no timing.
- Auto-scroll pauses when the user scrolls manually and resumes after a few seconds.
- Controls: seek bar, shuffle, previous, play/pause, next, repeat (off / all / one).
- Secondary: queue (C02), sleep timer (C05), add to playlist (C04), floating lyrics
  toggle, favorite.
- Overflow: sync offset ±0.5 s (saved per recording), font size, edit song info (S09),
  report wrong lyrics (P2).
- Background colors adapt to album art. Light and dark variants.
- Also used in "view only" mode for detected songs (no transport controls; position
  follows the other app).

### S09 — Edit song info · P2
**Purpose:** fix wrong metadata of local files.
- Edit title, artist, album, track number, album art (from gallery).
- Saved in Zema's database (does not rewrite the audio file) and used for matching.

---

## 4. Library

All library tabs work offline from the device's audio files.
Common features: song menu (C03) on every track, Play / Shuffle buttons on every list,
mini player (C01) stays visible.

### S10 — Library: Tracks · P1 · Stitch §8A
- All local tracks, with count.
- Search-as-you-type filter.
- Sort: title, artist, album, date added, duration; ascending/descending.
- Alphabet fast-scroll.
- Row: art, title, artist · duration, lyrics status icon (synced / text / none).
- Multi-select: add to playlist, add to queue, favorite, hide.

### S11 — Library: Folders · P1 · Stitch §8B
- Lists folders that contain audio, from the file system (e.g. Music, Download,
  Telegram Audio, WhatsApp Audio) with song count and path.
- S11a **Folder contents**: breadcrumb path, subfolders first, then tracks; Play all /
  Shuffle.
- Hide / unhide a folder from the whole library (also in Settings).

### S12 — Library: Albums · P1 · Stitch §8C
- Grid of albums grouped from file metadata; sort by name / artist / year.
- S12a **Album detail**: cover, name, artist, year, track count, total duration,
  numbered track list, Play / Shuffle.

### S13 — Library: Artists · P2
- List of artists with avatar (from album art) and song count.
- S13a **Artist detail**: albums and songs by that artist; Play / Shuffle.

### S14 — Library: Favorites · P1 · Stitch §9A
- All favorited songs; search, Play / Shuffle.
- Remove with undo.
- Favorites can include local tracks and cloud songs (detected from YouTube/Telegram).

### S15 — Library: Playlists · P1 · Stitch §9B
- "Create playlist" card, then user playlists (cover collage, name, count).
- Auto playlists (read-only): Recently added, Most played, Recently played.

### S16 — Create / rename playlist dialog · P1 · Stitch §9C
- Name (required, unique), optional description. Create / Save.

### S17 — Playlist detail · P1 · Stitch §9D
- Cover collage, name, count, duration, Play / Shuffle.
- Reorder by drag, remove by swipe (with undo).
- Menu: rename, change cover, delete playlist (with confirmation).
- "Add songs" → S18.

### S18 — Add songs picker · P1 · Stitch §9E
- Searchable list of all tracks with checkboxes; sticky "Add N songs" button.
- Songs already in the playlist are marked.

---

## 5. Contribute (P2)

All contribute screens require sign-in. Guests who open the tab see a sign-in prompt
(→ S24) with an explanation.

### S19 — Add lyrics · P2 · Stitch §10
**Step 1 of 4.**
- Fields: title, transliteration (optional), artist, album (optional).
- Duplicate check while typing the title: "A similar song exists — add a recording to
  it instead?"
- Block editor: block type (Verse / Chorus / Bridge) + lines; add, delete, reorder.
- Play order strip: ordered references to blocks, so the chorus is written once and
  repeated.
- "Paste all text" auto-splits into blocks (blank line = new block; repeated block =
  chorus).
- Draft saved automatically on the device.

### S20 — Link recording · P2 · Stitch §11A
**Step 2 of 4.**
- Source options:
  - YouTube link → fetch title, thumbnail, duration; store video ID.
  - Telegram → user shares the audio file to Zema (Android share intent).
  - Local file → pick from library.
- Artist / choir name.
- Can also be opened from Song detail to add another recording to an existing song.

### S21 — Tap-to-sync editor · P2 · Stitch §11B
**Step 3 of 4.**
- Plays the recording; big "Tap for next line" button records the current time for the
  highlighted line.
- Undo last tap, rewind 5 s, playback speed 0.75× / 1×, nudge a single timestamp.
- Chorus repeats reuse the same lines; each occurrence gets its own time.
- Preview mode plays back with highlighting.
- Optional step: users can submit text only and sync later.

### S22 — Review & submit · P2
**Step 4 of 4.**
- Summary: lyrics, recording, sync status.
- Submit → status "Pending"; a copy is saved locally so the user sees it immediately.
- Success message and link to S23.

### S23 — My contributions · P2 · Stitch §13A
- Tabs: Pending / Approved / Needs changes / Rejected.
- Card: song, type (lyrics / sync / recording link), date, moderator comment.
- "Edit" on "Needs changes" reopens the flow with the submitted data.
- Notification when status changes (P3).

### S23m — Moderator review queue · P2 · Stitch §13B
- Visible only to users with the Moderator role.
- Queue of pending submissions, oldest first; filter by type.
- Review detail: diff of submitted vs current lyrics, sync preview player, checklist,
  actions Approve / Request changes (comment required) / Reject (reason required).
- Approved content becomes visible to all users.

---

## 6. Account & backup

### S24 — Sign in · P2 · Stitch §12
- Benefits list (contribute, back up, restore).
- Single option: **Continue with Google** (Gmail account). No passwords, phone number
  or OTP; account recovery is handled by Google.
- Name and avatar are taken from the Google account (name editable in S25).
- Cancelled or failed sign-in returns to the previous screen with a short message.
- "Continue as guest".
- After sign-in: if a backup exists → S26, otherwise back to where the user came from.

### S25 — Profile · P2 · Stitch §12
- Avatar, display name (editable), role badge (Contributor / Moderator).
- Stats: lyrics added, recordings synced, approved.
- Links: My contributions (S23), Backup & sync, Settings (S28), Sign out.
- Guest version: guest icon + "Sign in" card + link to Settings.

### S25b — Backup & sync · P2 · Stitch §12
- Last backup time; "Auto backup" toggle (e.g. daily on Wi-Fi); "Back up now";
  "Restore".
- Included: favorites, playlists (with track identities so they can be re-matched on a
  new phone), song matches, sync offsets, floating lyrics settings, app settings.
- Not included: audio files themselves.

### S26 — Restore on new phone · P2 · Stitch §12
- "We found your backup from <date> — N favorites, N playlists, settings."
- Restore → re-links playlists/favorites to tracks found on this phone; reports songs
  not found on the device.
- Start fresh → keeps backup in the cloud, starts empty locally.

---

## 7. Detection & floating lyrics (Android)

### S27 — Floating lyrics overlay · P1 · Stitch §6
Runs over other apps; started by background detection even when Zema is closed.
- **Detection:** listens to media sessions of enabled apps (YouTube, YouTube Music,
  Telegram, others); reads title, artist, duration, position, play/pause.
- **Matching:** cleans the title and matches to a known song/recording. Order:
  remembered match (S27 state 4) → exact recording link (YouTube video ID / file) →
  fuzzy title match.
- **States:**
  1. Bubble — docked, draggable; tap to expand.
  2. Compact bar — current line + next line; expand, lock (click-through), close.
  3. Expanded panel — resizable; several lines; font size, opacity, sync offset,
     "Open in Zema".
  4. Match confirmation — "Is this the song?" with best match; Yes / Choose another /
     Not a mezmur. Answers are remembered.
  5. No lyrics — show plain text if available; "Help sync it" (P2); Dismiss.
- Follows play/pause and seeking in the other app; hides when playback stops (after a
  delay) or the user closes it.
- Position, size and opacity remembered.
- Does not appear while Zema itself is in the foreground (configurable).

### S27s — Floating lyrics & detection settings · P1 · Stitch §7
- Master switch: show floating lyrics when a song is detected.
- Apps to detect from: YouTube, YouTube Music, Telegram, Zema player, other apps.
- When to show: automatically / ask first (bubble) / only on tap.
- Appearance with live preview: text size, lines (1 / 2 / full), opacity, background
  (dark / light / transparent), position, show transliteration.
- Matching: remember confirmations, show low-confidence matches; "Clear remembered
  matches".
- Permission status rows with "Fix" buttons.

---

## 8. Settings

### S28 — Settings · P1 · Stitch §14
- **General:** language, theme (light / dark / system).
- **Lyrics:** font size, show transliteration, default sync offset.
- **Floating lyrics & detection** → S27s.
- **Library:** included/excluded folders, rescan, ignore audio shorter than N seconds
  (hides voice notes), offline lyrics download and storage used (P2).
- **Playback:** sleep timer default, gapless playback, pause when headphones are
  unplugged, audio focus behavior.
- **Account & backup** → S25 / S25b.
- **Privacy:** explanation of what is read from notifications.
- **About & help:** permission guide, version, licenses, feedback.

---

## 9. Shared components

| ID | Component | Priority | Function |
|---|---|---|---|
| C01 | Mini player | P1 | Above bottom nav when playing: art, title, play/pause, next, progress; tap → S08. Shows detected songs too (view only). |
| C02 | Queue sheet | P1 | Current queue; drag to reorder, swipe to remove, clear queue. |
| C03 | Song menu | P1 | Play next, add to queue, add to playlist, favorite, go to album, go to artist, view lyrics, edit info, hide, share. |
| C04 | Add to playlist sheet | P1 | "New playlist" + existing playlists with checkmarks. |
| C05 | Sleep timer sheet | P1 | 15 / 30 / 45 / 60 min, end of current song, custom; shows remaining time; cancel. |
| C06 | Lyrics view | P1 | Shared widget for synced and plain lyrics, used in S07, S08, S21, S27. |
| C07 | Empty / error / offline states | P1 | Consistent messages and retry actions across screens. |
| C08 | Media notification & lock screen controls | P1 | Standard Android/iOS playback controls for the in-app player. |
| C09 | Guest sign-in prompt | P2 | Shown when a guest tries a sign-in-only action. |

---

## 10. Suggested intents (for specsmd)

Each intent maps to a group of screens; build in this order.

| # | Intent | Screens | Priority |
|---|---|---|---|
| 001 | **Local music player & library** | S08 (local), S10–S18, C01–C05, C08, S28 (general, library, playback) | P1 |
| 002 | **Lyrics display & cloud catalog (read-only)** | S06, S07 (lyrics/info), S08 lyrics, C06; search normalization | P1 |
| 003 | **Background detection & floating lyrics** | S03, S05 now-detected card, S27, S27s; Kotlin detection + overlay | P1 |
| 004 | **Onboarding & home** | S01–S05 | P1 |
| 005 | **Accounts, backup & restore** | S24–S26, S25b | P2 |
| 006 | **Contribution & sync editor** | S19–S23, S07 recordings tab, S09 | P2 |
| 007 | **Moderation** | S23m, roles | P2 |

Recommended first step: a short **spike** in intent 003 to prove that the Kotlin
detection service can open the overlay while the Flutter app is closed — the riskiest
technical part of the project.

## Open decisions

1. Backend: Firebase or Supabase (affects 002, 005, 006, 007).
2. Overlay: Flutter UI (`flutter_overlay_window`) or native Kotlin view.
3. Where cloud lyrics come from at launch: seed an initial catalog yourself, or start
   empty and rely on contributions.
4. Moderator selection: invited only, or promoted by reputation.
