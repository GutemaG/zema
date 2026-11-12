# Zema — Build Roadmap (specsmd input)

This is the **starting document for specsmd**. It holds everything needed to create intents:
product summary, decisions, domain model, and the build order split into **stages, from
simplest to most complex**. Each stage is one specsmd intent.

Supporting documents (read when a stage points to them):

| Document | Use it for |
|---|---|
| `docs/screens.md` | Full detail of every screen (IDs like S10) and shared component (C01) |
| `docs/design-system.md` | Colors, fonts, spacing, components; screen images in `design/screens/` |
| `docs/flutter-build-notes.md` | Kotlin vs Dart split, packages, now-playing event format, old-repo mapping |

---

## 1. Product summary

**Zema** is an Android-first music player and synchronized-lyrics companion for Ethiopian
Orthodox Tewahedo mezmur (spiritual songs).

- Plays the user's **local audio files** with a full library (tracks, folders, albums,
  artists, favorites, playlists).
- Shows **synced lyrics** (current line highlighted) for songs that have them.
- Detects mezmur playing in **YouTube, Telegram and other apps** — even when Zema is closed
  — and shows lyrics in a **floating window** over that app (Android only).
- The **community contributes** lyrics and sync timings; **moderators** approve them.
- **Google sign-in** is only needed to contribute and to back up / restore on a new phone.
  Everything else works as a guest.

**Users:** listeners of all ages in Ethiopia and the diaspora, choir members. Many read
mainly Ethiopic script; many phones are mid/low-end (Tecno, Infinix, Samsung A-series)
with aggressive battery savers and unstable internet.

**Platforms:** Android first. iOS later, limited to the in-app player and lyrics (iOS does
not allow reading other apps' playback or drawing overlays).

**Out of scope (whole product):** hosting or streaming audio, video playback, feast /
calendar content, payments, social features (comments, follows), phone or email login.

## 2. Decisions

### Made

| Area | Decision |
|---|---|
| Framework | Flutter (Dart 3.13, Flutter 3.47) |
| Repo | Monorepo with Dart pub workspace: `apps/mobile`, `apps/admin` (later), `packages/zema_core`, `packages/zema_data` (later), `backend/` |
| Shared logic | `packages/zema_core`: pure Dart (no Flutter, no backend) — models, lyrics, sync, search normalization, matching, repository interfaces |
| Native code | Kotlin, only for playback detection and the overlay (stage 7) |
| Auth | Google sign-in only |
| Design | Night Vigil palette (default) + Night Vigil · Wine (alternative); sans fonts (Inter + Noto Sans Ethiopic); see `docs/design-system.md` |
| Languages | English, Amharic, Afaan Oromoo, Tigrinya (UI in English first, other languages via ARB files) |
| Admin | Flutter web site, deployed as static files (stage 8) |

### Proposed defaults — confirm during inception

| Area | Proposal | Reason |
|---|---|---|
| State management | Riverpod | Testable, no BuildContext needed in services |
| Navigation | go_router | Deep links, nested tab navigation |
| Local database | Drift (SQLite) | Relational, typed queries, migrations |
| Audio | just_audio + audio_service | Background playback, notification and lock-screen controls |
| Library scan | on_audio_query (MediaStore) | Tracks, albums, artists, folders from the device |
| Backend | Supabase (Postgres, Auth, RLS) | Relational data, server-side Ethiopic search, row-level permissions |
| Theme | System / Light / Dark (default System), Night Vigil / Wine palette each in dark and light | Changed 2026-10-24 from dark-only at the product owner's request; light tokens are a draft |

### Still open

1. Sync editor variant: 7a list, 7b focus, 7c tap the line, 7d "we guess, you check"
   (needed before stage 6).
2. Overlay UI in Flutter (`flutter_overlay_window`) or native Kotlin (decided by the
   stage 7 spike).
3. How the first lyrics catalog is seeded (needed before stage 4).
4. How moderators are chosen (needed before stage 6).

## 3. Domain model (summary)

Full list in `docs/flutter-build-notes.md` → "Core domain model".

- **Song** — canonical text: title, transliteration, artist, album.
- **LyricSection** — verse / chorus / bridge with lines; **PlayOrder** — sequence of
  sections (chorus written once, repeated in the order).
- **Recording** — one performance: artist/choir, source (local file, YouTube video ID,
  Telegram file), duration.
- **SyncTiming** — start time per line occurrence, per recording.
- **LocalTrack**, **Folder**, **Album**, **Artist** — from the device's audio files.
- **Playlist**, **Favorite**, **PlayHistory** — the user's library data.
- **SourceMatch** — remembered link from a detected source to a recording.
- **Contribution** — submitted lyrics / sync / recording link + review status.
- **UserBackup** — favorites, playlists, matches, settings.

---

## 4. Stages (intents), simplest → most complex

| Stage | Intent | Needs internet / backend | Native Kotlin | Complexity |
|---|---|---|---|---|
| 1 | `001-app-foundation` | No | No | ★☆☆☆☆ |
| 2 | `002-local-library-and-player` | No | No | ★★☆☆☆ |
| 3 | `003-lyrics-engine-and-display` | No (sample data) | No | ★★★☆☆ |
| 4 | `004-cloud-lyrics-catalog` | Yes | No | ★★★☆☆ |
| 5 | `005-accounts-backup-restore` | Yes | No | ★★★☆☆ |
| 6 | `006-contribution-and-sync-editor` | Yes | Small (share intent) | ★★★★☆ |
| 7 | ~~`007-background-detection-floating-lyrics`~~ merged into 009 | — | — | — |
| 8 | `008-admin-website` | Yes | No | ★★★☆☆ |
| 9 | `009-audio-fingerprint-library` (+ former 007) | Yes | **Yes** | ★★★★★ |
| 10 | `010-listen-to-identify` | Yes | Yes (microphone service) | ★★★★★ |
| 11 | `011-share-lyrics-clips` | No | Maybe (spike decides) | ★★★★☆ |
| 12 | `012-ai-lyrics-from-audio` | Yes | No | ★★★★☆ |

Every stage ends with a working, installable app. Stages 1–3 need no backend at all.

> **Risk note:** stage 7 is the most complex and the most uncertain (Android background
> limits, OEM battery savers). Its **spike** (a throw-away prototype proving the Kotlin
> listener can open an overlay while the app is closed) can be run any time after stage 1,
> before investing in later stages.

---

### Stage 1 — `001-app-foundation` ★☆☆☆☆

**Goal:** an empty but real app: themed, navigable, translatable, tested.

**Scope**
- App shell with bottom navigation: Home, Search, Library, Contribute (placeholder
  content).
- Theme from design tokens: `ZemaColors` ThemeExtension with Night Vigil and Wine; palette
  switch saved locally.
- Fonts bundled as assets: Inter, Noto Sans Ethiopic (fallback).
- Routing (go_router), state management (Riverpod) wired.
- Localization scaffold: ARB files for en, am, om, ti (English complete; others fall back
  to English); language switch saved locally.
- Settings screen (S28) with only: Language, Palette, About.
- App name "Zema", app ID `com.zemaapp.zema`, launcher icon placeholder.
- Tooling: lints, `flutter test` and `dart test` passing, a GitHub Actions workflow running
  analyze + tests (optional).

**Done when**
- App launches on the emulator and a real phone; four tabs switch.
- Changing palette or language updates the whole UI immediately and survives restart.
- Ethiopic text renders with the bundled font (no system fallback boxes).

**Out of scope:** any real data, audio, lyrics.

---

### Stage 2 — `002-local-library-and-player` ★★☆☆☆

**Goal:** a complete offline music player for the phone's audio files.

**Screens:** S10 Tracks, S11 Folders (+ folder contents), S12 Albums (+ album detail),
S13 Artists (+ detail), S14 Favorites, S15–S18 Playlists, S08 Now Playing (controls only,
lyrics area shows "No lyrics yet"), S28 Library + Playback settings.
**Components:** C01 mini player, C02 queue, C03 song menu, C04 add-to-playlist, C05 sleep
timer, C07 empty states, C08 media notification / lock screen.

**Key requirements**
- Request audio permission (`READ_MEDIA_AUDIO`; older Android: storage) with a clear
  explanation and a "grant later" path.
- Scan the device library; folders derived from file paths; hide folders; ignore audio
  shorter than N seconds (default 30 s, hides voice notes).
- Playback continues in the background with notification and lock-screen controls;
  shuffle, repeat (off / all / one), queue reorder, sleep timer.
- Favorites, playlists (create, rename, delete, reorder, add/remove), play history and play
  counts stored in Drift.
- Auto playlists: Recently added, Most played, Recently played.
- Search-as-you-type filter in Tracks.

**Done when**
- 1,000-track library scans in under 5 s on a mid-range phone; lists scroll smoothly.
- Music keeps playing with the screen off for 30+ minutes; controls work from the
  notification.
- Favorites and playlists survive app restart.

**Out of scope:** lyrics, accounts, cloud, edit song info (S09, later).

---

### Stage 3 — `003-lyrics-engine-and-display` ★★★☆☆

**Goal:** show synced lyrics for local songs, using bundled sample data — proving the
lyrics model and sync engine before any backend exists.

**Scope**
- `zema_core`: Song, LyricSection, PlayOrder, Recording, SyncTiming models; play-order
  expansion; **sync engine** (position + offset → current line); **Ethiopic search
  normalization** (ሀ/ሐ/ኀ, ሰ/ሠ, አ/ዐ, ጸ/ፀ…, transliteration ↔ Ethiopic, title cleanup);
  `LyricsRepository` interface. All with unit tests.
- `FakeLyricsRepository` loading a bundled JSON of sample songs.
- Link local tracks to songs: automatic match by normalized title + artist; manual
  "Match" action; matches saved locally.
- C06 lyrics view in S08 Now Playing: current line highlighted, auto-scroll, tap a line to
  seek, chorus markers, transliteration toggle, font size, per-recording sync offset.
- S07 Song detail (Lyrics and Info tabs).
- S06 Search across local library and sample lyrics (songs, artists, albums, lyric text).
- S05 Home (continue listening, recently played, playlists).
- S28 Lyrics settings.

**Done when**
- A sample song plays with lines highlighted within ±0.3 s of the timing data.
- Searching "kidist", "ቅድስት" or "ቅዱስት" finds the same song.
- Unit tests cover sync engine, play order and normalization.

**Out of scope:** network, contributions.

---

### Stage 4 — `004-cloud-lyrics-catalog` ★★★☆☆

**Goal:** replace sample data with the shared online catalog (read-only).

**Scope**
- Backend in `backend/`: schema migrations (songs, sections, recordings, sync timings,
  contributions, users/roles), Row Level Security (public read of approved content),
  server-side search using the same normalization rules, seed script for the initial
  catalog.
- `packages/zema_data`: Supabase implementation of `LyricsRepository`.
- Offline-first: fetched lyrics cached in Drift; app works offline with cached data;
  optional "download all lyrics for offline" (S28).
- S07 Recordings tab (read-only); S05 "New lyrics from the community".
- Report wrong lyrics (stored as a report for moderators).

**Done when**
- Lyrics for a matched song load from the backend and still show with no internet later.
- Search returns cloud results in under 1 s on 3G-class connections.

**Out of scope:** sign-in, writing data.

---

### Stage 5 — `005-accounts-backup-restore` ★★★☆☆

**Goal:** optional Google sign-in, backup and restore across phones.

**Screens:** S04 Account choice, S24 Sign in (Google only), S25 Profile, S25b Backup &
sync, S26 Restore on new phone; C09 guest sign-in prompt.

**Key requirements**
- Guest is the default; sign-in only from Profile, Contribute, or backup prompts.
- Backup: favorites, playlists (with track identity: title, artist, duration, file name),
  song matches, sync offsets, settings. Manual and automatic (daily on Wi-Fi).
- Restore re-links playlists/favorites to tracks found on the new phone and lists songs
  not found.
- Users can only read and write their own backup (RLS).

**Done when**
- Sign in on phone A, back up, sign in on phone B, restore → same favorites and playlists
  (for songs present on B) and same settings.

---

### Stage 6 — `006-contribution-and-sync-editor` ★★★★☆

**Goal:** signed-in users add lyrics, link recordings, sync timings; moderators approve.

**Screens:** S19 Add lyrics (block editor, play order, paste-and-split, duplicate check),
S20 Link recording (YouTube link, Telegram share, local file), S21 Sync editor (variant
chosen from 7a–7d), S22 Review & submit, S23 My contributions, S23m Review queue (in-app
for moderators until stage 8), S09 Edit song info, S07 "Link a recording" entry.

**Key requirements**
- Drafts saved locally; submission creates a pending contribution.
- Chorus written once; each repeat gets its own timing.
- YouTube link → video ID, title, duration; Telegram audio received through Android share.
- Moderator role in the backend; approve / request changes (comment) / reject (reason);
  approved content becomes public.
- Validation (shared in `zema_core`): title required, at least one section, timestamps
  strictly increasing.

**Done when**
- A user submits lyrics + sync for a local song; a moderator approves; another device sees
  the synced lyrics.

---

### Stage 7 — merged into Stage 9 (2026-11-03)

Background detection and floating lyrics are now Part B of `009-audio-fingerprint-library`.

---

### Stage 8 — `008-admin-website` ★★★☆☆

**Goal:** a web dashboard for moderators.

**Scope:** `apps/admin` (Flutter web, shares `zema_core`): sign in with Google (moderator
role required by backend rules), review queue with side-by-side diff and sync preview,
browse / search / edit / unpublish songs and recordings, handle wrong-lyrics reports.
Deployed as static files (Vercel or similar) via GitHub Actions.

**Done when**
- A moderator can approve a submission from the website and it appears in the app.

---

### Stage 9 — `009-audio-fingerprint-library` ★★★★★ (includes former 007)

**Goal:** know which song is playing and show its lyrics at the current line, in Zema or
in a floating window over other apps.

**Key requirements** (full list in the intent's requirements.md)
- Identify a song from a few seconds of audio at any point, through the microphone or
  from a file, with its position. Offline index on the phone; online lookup otherwise.
- Listen from the app, a lock-screen tile/control and a home-screen widget.
- Fingerprints only, never audio; catalog fingerprints from the seed tool,
  contributions and opted-in libraries.
- Android: detect YouTube/Telegram playback via media sessions; floating lyrics window,
  even when Zema is closed; listening as fallback when the title doesn't match.

**Done when**
- A catalog recording played from a speaker 2 m away, starting anywhere, is identified
  within 10 s (also offline) and its lyrics show at the right line.
- With Zema closed, a matched mezmur in YouTube opens floating lyrics within 3 s, in sync
  within ±0.5 s, on two phone brands.

**Spikes first:** peak-pair fingerprint on real mezmur files and microphone recordings;
listener → overlay launch with the app process killed, on a real phone.

---

### Stage 10 — `010-listen-to-identify` ★★★★★

**Goal:** identify a song playing nearby through the microphone and show its lyrics in
sync.

**Key requirements**
- "Keep listening": started by the user, listens in bursts with a visible notification,
  stops by itself (default 1 hour). No always-on listening; iOS only while Zema is open.
- Audio is never uploaded or saved.

**Done when**
- A catalog recording played from a speaker 2 m away is identified within 10 s and its
  lyrics show at the right line.

---

### Stage 11 — `011-share-lyrics-clips` ★★★★☆

**Goal:** share part of a song, up to 1–2 minutes, as a video with synced lyrics to
TikTok, YouTube Shorts, Snapchat and other apps.

**Key requirements**
- A clip editor picks the start and end (60 s default, 2 min allowed), snapping to lyric
  lines, with a preview.
- The phone makes a 1080×1920 MP4: cover art, the lyrics highlighted in time, and the
  audio cut from the user's own file. Offline, with progress and cancel; nothing is
  uploaded.
- The video goes to the system share menu or the gallery. A short note says platforms
  may mute copyrighted music.

**Done when**
- A 60 s clip from Now Playing renders on a mid-range Android phone and on iOS, plays in
  TikTok, YouTube Shorts and Snapchat, and its lyrics stay within ±0.2 s of the audio.

**Spike first:** a maintained FFmpeg build or native encoding (AVFoundation,
MediaCodec); measure render time, app size and licence.

Needs only 002 and 003, so it can be built at any point after them.

---

### Stage 12 — `012-ai-lyrics-from-audio` ★★★★☆

**Goal:** write a first draft of a song's lyrics from its audio with a speech-to-text
service, for a person to check and submit.

**Key requirements**
- "Write lyrics with AI" on a track with no lyrics: consent each time, then the audio
  goes through a backend function (the provider key stays on the server) and is deleted
  after.
- The text, and timings if any, open as an "AI draft" in the contribution editor (006);
  nothing generated is published without review.
- Daily limits and a spend cap; the provider is swappable behind an interface.

**Done when**
- A mezmur with no lyrics gets a draft in the editor, and checking it is clearly faster
  than typing the lyrics from scratch.

**Spike first:** compare speech-to-text services (and an on-phone model) on real sung
Amharic, Afaan Oromoo and Tigrinya, with and without vocal separation; choose one.

Note: this is the only feature that uploads audio, an exception to the "No audio
uploaded" rule below, and only with the user's consent.

---

## 5. Non-functional requirements (all stages)

| Area | Requirement |
|---|---|
| Offline | Library, player, cached lyrics and floating lyrics work without internet |
| Performance | Cold start < 2 s on mid-range phones; smooth 60 fps lists |
| Battery | Detection uses system callbacks (no polling); no constant foreground work when nothing plays |
| Accessibility | Touch targets ≥ 44 px; text contrast ≥ 4.5:1; adjustable lyrics size; screen-reader labels |
| Localization | No hard-coded UI strings; layouts tolerate longer translations and Ethiopic script |
| Privacy | No audio uploaded; notification text never read; backups private to the user |
| Security | All write permissions enforced by backend rules, not by the app or website |
| Quality | `zema_core` logic unit-tested; analyzer clean; each stage ends releasable |

## 6. Starting specsmd

1. Run `/specsmd-master-agent` and initialize the project. Project type: **frontend-app**
   (mobile app; the backend and admin site come in later stages).
2. When it sets up standards (tech stack, coding standards, architecture), point it to
   sections 2–3 of this file and `docs/flutter-build-notes.md`.
3. Create the first intent with `/specsmd-inception-agent`:
   > Create intent `001-app-foundation` from `docs/roadmap.md` Stage 1. Use
   > `docs/design-system.md` for theme tokens and fonts, and `docs/screens.md` S28 for the
   > settings screen.
4. Repeat for each stage in order. Before each intent, resolve the open decisions it
   depends on (section 2).
