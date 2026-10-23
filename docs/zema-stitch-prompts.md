# Zema — Google Stitch Prompts & Flutter Build Notes

Music player and lyrics companion for Ethiopian Orthodox Tewahedo mezmur. Users listen on
YouTube, Telegram, or local files; the app detects what is playing (even in the background)
and shows synchronized lyrics in a floating window. The community contributes and syncs
lyrics; signed-in users can back up their data and restore it on a new phone.

"Zema" is a working name — replace it everywhere if you choose another.

## How to use these prompts

1. Paste the **Design brief** (section 0) into Stitch first.
2. Then generate one screen at a time with the screen prompts (sections 1–14).
   Stitch does better with one or two screens per prompt than a whole app at once.
3. If later screens drift in style, paste the brief again.
4. Stitch exports HTML/CSS or Figma, not Flutter — use its output as a visual reference
   and build the widgets in Flutter yourself.

---

## 0. Design brief (paste first)

```
Design a mobile app (Android first, 390×844) called "Zema" — a music player and
synchronized-lyrics companion for Ethiopian Orthodox Tewahedo mezmur (spiritual songs).
Users play mezmur from local audio files inside Zema, or listen on YouTube or Telegram;
Zema detects what is playing and shows synchronized lyrics, including a floating lyrics
window over other apps. The community contributes and syncs lyrics; trusted moderators
approve them. The app is focused only on music and lyrics.

Audience: listeners of all ages in Ethiopia and the diaspora, including choir members.
Prioritize readability, large tap targets, and clear icons with labels.

Localization: the app will be fully localized (English, Amharic, Afaan Oromoo, Tigrinya).
Design the UI in English, but leave room for longer translated labels and for Ethiopic
(Ge'ez) script. Song content (titles, lyrics) is often in Ethiopic script, sometimes in
Latin script — layouts must handle both.

Visual style: calm, modern, slightly warm — inspired by Ethiopian manuscripts and woven
textiles, but minimal and not decorative-heavy.
- Colors: deep burgundy (#6B1E2E) primary, warm gold (#C9A227) accent, parchment cream
  (#F7F1E3) light background, warm near-black (#1C1412) for dark mode. Dark mode is
  important.
- A thin tilet-style woven pattern used sparingly as an accent strip on headers.
- Typography: Noto Serif Ethiopic for song titles and lyrics, Noto Sans / Noto Sans
  Ethiopic for UI. Lyrics use generous line height (1.6–1.8) because Ethiopic script
  needs vertical space.
- Material 3 components, 16px rounded corners, soft shadows.
- A persistent mini player above the bottom navigation when something is playing.
- Bottom navigation with 4 tabs: Home, Search, Library, Contribute.

Use realistic sample content, never lorem ipsum:
- Song titles: "ስብሐት ለእግዚአብሔር", "ሃሌ ሉያ", "ቅድስት ድንግል ማርያም", "ይትባረክ",
  and a Latin-script one such as "Kidist Dingil Mariam"
- Artists: "Zemari <name>", "Sunday School Choir"
- Lyrics: verse lines and a repeated refrain/chorus section
```

---

## 1. Onboarding and permission setup

```
Using the Zema design brief, create a 4-step onboarding flow (show all 4 screens):

1. Welcome: simple logo mark in a gold circle, app name "Zema", tagline "Listen to
   mezmur with synced lyrics". Language selector (English, አማርኛ, Afaan Oromoo, ትግርኛ),
   each shown in its own language. Primary button "Get started".

2. How it works: 3 illustrated steps — play mezmur on YouTube / Telegram / your music
   files (show those three source icons) → Zema recognizes the song → floating lyrics
   appear.

3. Permissions setup (critical): a checklist of 3 permission cards, each with icon,
   short explanation, and status (green "Granted ✓" or an "Allow" button):
   - "Notification access" — to see what YouTube / Telegram is playing
   - "Display over other apps" — to show floating lyrics
   - "Music & audio files" — to play and organize your music
   Privacy note: "Zema only reads song titles, never your messages."
   "Skip for now" link at the bottom.

4. Account choice: "Continue as guest" (primary, full width) and "Sign in" (secondary)
   with a "Continue with Google" button. Note: guests can listen and read lyrics;
   signing in is needed to contribute lyrics or keep your library when changing phones.
```

## 2. Home

```
Using the Zema design brief, create the Home screen (music only):
- Header: greeting, search shortcut icon, profile avatar (or "Guest" icon).
- "Now detected" card at the top when music is playing in another app: source badge
  (YouTube red / Telegram blue / Local), song title, artist, mini progress bar, buttons
  "Show floating lyrics" and "Open lyrics".
- Quick action row: Shuffle all, Favorites, Recently added, Playlists.
- Section "Continue listening": horizontal cards with album art and progress.
- Section "Recently played": list rows with source icon.
- Section "Your playlists": horizontal playlist cards.
- Section "New lyrics from the community": rows with a gold "Synced" badge for songs
  with timestamps or a grey "Text only" badge.
- Mini player above the bottom navigation (Home active).
```

## 3. Search

```
Using the Zema design brief, create the Search screen:
- Large search field "Search songs, artists, albums or lyrics". Users type with any
  keyboard — Ethiopic script, Latin, or transliteration all work (e.g. "kidist" finds
  "ቅድስት"). Show a small hint about this under the field.
- Scope chips: All, Songs, Artists, Albums, Lyrics (search inside lyric text),
  On this device.
- Results grouped by type: Songs (title, artist, synced badge, favorite heart, overflow
  menu), Artists (round avatars), Albums (square art), Lyrics matches (the matched line
  with the search term highlighted).
- Empty state (before typing): recent searches with clear buttons and popular songs.
- No results state: "No songs found" with button "Add this song's lyrics".
```

## 4. Song detail

```
Using the Zema design brief, create the Song detail screen:
- Top: album art, title "ስብሐት ለእግዚአብሔር" (large serif), transliteration below,
  artist, album, Play button, favorite, add-to-playlist, and share buttons.
- Tabs: Lyrics | Recordings | Info.
- Lyrics tab: full text with clear section structure — verses as normal paragraphs,
  refrain/chorus blocks with a gold "Chorus" label and soft gold left border, and
  a "↻ repeat" note where the chorus repeats. Font size A−/A+ control.
- Recordings tab: versions by different artists/choirs, each row with artist,
  duration, source icon (YouTube / Telegram / Local), sync status ("Synced" /
  "Needs sync"), and play button. "Link a recording" button at the bottom.
- Info tab: album, artist, contributors with avatars, approved-by-moderator badge,
  last updated.
```

## 5. Now playing with synced lyrics

```
Using the Zema design brief, create the full-screen Now Playing screen (dark mode):
- Background: dark gradient tinted by the album art colors.
- Header: collapse arrow, source badge ("Playing from Local files"), overflow menu.
- Album art small at top with title and artist, favorite heart.
- Center: synchronized lyrics, 7–9 lines visible. Current line large, bright, bold;
  previous lines dimmed; next lines medium opacity. Chorus lines show a small gold
  "Chorus" marker. Tapping a line seeks to it.
- Bottom: seek bar with times, shuffle, previous, play/pause, next, repeat; secondary
  row: queue, sleep timer, add to playlist, floating lyrics toggle.
- Overflow menu: sync offset (±0.5s), font size, edit song info, report wrong lyrics.
- Also show a light-mode variant and a "Queue" bottom sheet with drag-to-reorder.
```

## 6. Floating lyrics window (the main feature)

```
Using the Zema design brief, design the floating lyrics overlay that appears on top of
other apps. Show it over a blurred mock YouTube app and a blurred Telegram chat with an
audio player. Show these 5 states side by side:

1. Collapsed bubble: round 56px gold-bordered bubble with the logo and a small pulsing
   music indicator, docked at the screen edge.
2. Compact bar: rounded translucent dark card (~90% width, 2 lines) showing the current
   lyric line large and the next line dimmed; small controls: expand, lock
   (click-through), close.
3. Expanded panel: resizable card (~60% height) with 6–8 synced lines, drag handle,
   font size A−/A+, opacity slider, sync offset ±, "Open in Zema".
4. Match confirmation: "Is this the song?" showing the detected title from YouTube
   ("ስብሐት ለእግዚአብሔር - Zemari ... | Official Video") and Zema's best match with
   confidence; buttons "Yes", "Choose another", "Not a mezmur".
5. No lyrics yet: "No lyrics for this recording yet" with buttons "Show text without
   sync", "Help sync it", "Dismiss".
```

## 7. Floating lyrics and detection settings

```
Using the Zema design brief, create the Floating Lyrics & Detection settings screen:
- Master switch: "Show floating lyrics when a song is detected".
- Section "Detect from apps": toggles with app icons for YouTube, YouTube Music,
  Telegram, Zema player, and "Other music apps".
- Section "When to show": Automatically / Ask me first (show bubble) / Only when I tap
  the bubble. Toggle "Only when Zema is in the background".
- Section "Appearance": live overlay preview at the top that updates as settings
  change; text size, lines shown (1 / 2 / full), opacity, background (dark / light /
  transparent), position (top / middle / bottom), show transliteration toggle.
- Section "Matching": "Remember my confirmations", "Show low-confidence matches".
- Section "Permissions": Notification access and Display over other apps, each with
  status and a "Fix" button.
```

## 8. Library — Tracks, Folders, Albums

```
Using the Zema design brief, create the Library screen with scrollable tabs:
Tracks | Folders | Albums | Artists | Favorites | Playlists.
Show three of the tabs as separate screens:

A) Tracks: search field at the top that filters the list as you type; sort menu
   (title, artist, date added, duration) and "Shuffle all" button; track count
   ("248 songs"). Each row: album art thumbnail, title, artist · duration, small
   lyrics status icon (synced / text only / none), overflow menu (play next, add to
   queue, add to playlist, favorite, edit info, view lyrics). Alphabet fast-scroll
   on the right edge.

B) Folders: list of folders from the device file system (e.g. "Music", "Download",
   "Telegram Audio", "WhatsApp Audio") with folder icon, song count and path. Tapping a
   folder opens its contents: subfolders first, then tracks, with breadcrumb path at
   the top and "Play all" / "Shuffle" buttons. Option to hide a folder from the library.

C) Albums: 2-column grid of album covers with album name and artist; sort by name /
   artist / year. Tapping opens Album detail: large cover, album name, artist, year,
   song count, total duration, Play and Shuffle buttons, numbered track list.

Guest banner (dismissible): "Sign in to keep your playlists and favorites when you
change phones."
```

## 9. Library — Favorites and Playlists

```
Using the Zema design brief, create these Library screens:

A) Favorites tab: header with count, Play and Shuffle buttons, searchable list of
   favorite songs with heart icons (tap to remove, with undo snackbar).

B) Playlists tab: "Create playlist" card first, then playlist cards in a grid with a
   2×2 cover collage, name, and song count (e.g. "Morning", "Choir practice",
   "Road trip"). Also show auto playlists: Recently added, Most played,
   Recently played.

C) Create playlist dialog: name field, optional description, "Create" button.

D) Playlist detail: cover collage, name, song count and duration, Play / Shuffle,
   edit menu (rename, change cover, delete playlist), "Add songs" button, track list
   with drag handles to reorder and swipe to remove.

E) "Add songs" picker: searchable track list with checkboxes and a sticky
   "Add 5 songs" button.

F) "Add to playlist" bottom sheet (opened from any song menu): "New playlist" row at
   top, then existing playlists with checkmarks if the song is already in them.
```

## 10. Contribute: add lyrics

```
Using the Zema design brief, create the Contribute flow, step 1 "Add lyrics":
- Stepper: 1 Lyrics → 2 Link recording → 3 Sync → 4 Submit.
- Fields: song title, transliteration (optional), artist, album (optional).
- Lyrics editor organized as blocks: each block has a type dropdown (Verse / Chorus /
  Bridge) and a multiline text area. "Add block" button. A "Play order" strip below
  showing chips like [Verse 1] [Chorus] [Verse 2] [Chorus] that can be dragged to
  reorder; tap "+ Chorus" to repeat the chorus.
- "Paste all text" option that auto-splits into blocks.
- Duplicate warning card: "A similar song exists: ... — add a recording to it
  instead?"
```

## 11. Contribute: link recording and tap-to-sync

```
Using the Zema design brief, create two screens:

A) "Link recording": choose source — paste a YouTube link (with thumbnail and title
preview), share from Telegram (instructions: "Share the audio from Telegram to
Zema"), or pick a local file from the library. Artist/choir field and confirmation
of the song being linked.

B) "Tap to sync" editor: audio player at the top with waveform and current time.
Middle shows lyric lines; the next line to time is highlighted with a gold outline;
timed lines show their timestamp (01:23.4) on the right. Large full-width bottom
button "Tap for next line" — very big and thumb-friendly. Secondary controls: undo
last tap, rewind 5s, playback speed 0.75× / 1×, info chip "Chorus timing reused
automatically". Preview button plays back with synced highlighting.
```

## 12. Sign in, profile and backup

```
Using the Zema design brief, create the Sign in screen and the Profile screen.

Sign in: 3 benefit rows with icons — "Contribute and sync lyrics", "Back up favorites,
playlists & settings", "Restore on a new phone". One primary button "Continue with
Google" (standard Google sign-in button style), and a "Continue as guest" link.
No email, password or phone fields.

Profile: avatar, name, role badge (Contributor / Moderator), stats (lyrics added,
recordings synced, approved). Section "Backup & sync": last backup time, "Auto backup"
toggle, what is included (favorites, playlists, song matches, floating lyrics
settings, app settings), buttons "Back up now" and "Restore". Link to "My
contributions". Sign out.

Also create the "Welcome back" restore screen shown after signing in on a new phone:
"We found your backup from 3 days ago — 42 favorites, 5 playlists, settings."
Buttons "Restore" and "Start fresh".
```

## 13. My contributions and moderation

```
Using the Zema design brief, create two screens:

A) My contributions: tabs Pending / Approved / Needs changes. Each card shows the
song title, what was submitted (lyrics / sync / recording link), date, and for
"Needs changes" the moderator's comment with an "Edit" button.

B) Moderator review queue: list of submissions with contributor, type and
reputation. Review detail shows a side-by-side diff of submitted vs current lyrics,
playable sync preview, checklist (text correct, wording correct, sections correct,
timing correct), and buttons Approve / Request changes (with comment) / Reject.
```

## 14. Settings

```
Using the Zema design brief, create the Settings screen with grouped sections:
- General: Language, Theme (Light / Dark / System).
- Lyrics: font size, show transliteration, default sync offset.
- Floating lyrics & detection (link to its own screen).
- Library: music folders to include/exclude, rescan library, ignore short audio
  (e.g. under 30 seconds — hides voice notes), offline lyrics download & storage used.
- Playback: sleep timer default, gapless playback, audio focus behavior.
- Account & backup.
- Privacy: what Zema reads from notifications.
- About & help: how to grant permissions, version.
```

---

# Flutter build notes

## Can Kotlin be used in a Flutter app?

Yes. A Flutter app contains a normal Android project in `android/`, and you can put
Kotlin code in `android/app/src/main/kotlin/...`. Dart talks to it through **platform
channels**:

- `MethodChannel` for one-off calls (check/request permissions, open system settings,
  show/hide overlay).
- `EventChannel` for streams (the "now playing" events coming from YouTube/Telegram).

So the app is mostly Dart, with a small Kotlin layer for things Flutter cannot do by
itself. Background detection is one of those things.

## What must be Kotlin vs. what can be Dart

| Feature | Where | Notes |
|---|---|---|
| Detect what YouTube / Telegram / other apps are playing | **Kotlin** | `NotificationListenerService` + `MediaSessionManager.getActiveSessions()` → title, artist, duration, position, play state, package name. Not in the old repo; write new. |
| Keep detecting while Zema is closed | **Kotlin** | The system keeps the notification listener bound while access is granted, so it runs without the app open. |
| Floating lyrics overlay | Kotlin or Dart (decide in spec) | **Option A:** `flutter_overlay_window` plugin, so the overlay UI is Flutter (needs a running engine). **Option B:** native Kotlin overlay (reference: old `FloatingLyricsService.kt`). Because detection happens when the app may be closed, the native listener must be able to start the overlay on its own; this is the key technical decision to prototype first. |
| Permissions (notification access, overlay) | Kotlin + Dart | Open the system settings pages through a MethodChannel; show status in Dart UI. |
| Local library scan (tracks, folders, albums, artists) | Dart (+ plugin) | `on_audio_query` or a MediaStore query via a small Kotlin channel; folders come from each track's file path. |
| In-app player, queue, shuffle, sleep timer | Dart | `just_audio` + `audio_service` (replaces old Media3 `PlaybackService.kt`). |
| Playlists, favorites, local database / offline | Dart | `drift` (replaces Room). |
| Auth, cloud lyrics, backup | Dart | `firebase_auth` + `cloud_firestore`, or `supabase_flutter`. |
| Album-art colors | Dart | `ColorScheme.fromImageProvider` (replaces `AlbumArtPalette.kt`). |
| Localization | Dart | `flutter_localizations` + ARB files (en, am, om, ti). Old repo has `values-am` / `values-om` strings to reuse. |
| Matching / fingerprint | Dart | Must be Unicode-safe (see below). |
| iOS | — | iOS cannot read other apps' playback or draw overlays; iOS = in-app player and lyrics only. |

Suggested now-playing event (Kotlin → Dart via EventChannel):

```json
{
  "sourcePackage": "com.google.android.youtube",
  "title": "ስብሐት ለእግዚአብሔር - Zemari ... | Official Video",
  "artist": "Channel name",
  "durationMs": 312000,
  "positionMs": 45210,
  "positionUpdatedAt": 1761123456789,
  "playbackState": "playing"
}
```

Compute the live position as `positionMs + (now - positionUpdatedAt)` while playing,
and apply the user's sync offset.

## Using the old Kotlin repo (LyricFlow) as reference

| Old file | Use in Flutter version |
|---|---|
| `FloatingLyricsService.kt` | Reference for a native overlay (drag, resize, window flags). |
| `PlaybackService.kt` | Concept only → `just_audio` / `audio_service`. |
| `MusicRepository.kt` | Reference for scanning local audio from MediaStore. |
| `SongFingerprintUtils.kt` | Concept only. **Do not copy the regex** `[^a-z0-9]`: it deletes all Ethiopic characters. Normalize Unicode instead (fold ሀ/ሐ/ኀ, ሰ/ሠ, አ/ዐ, ጸ/ፀ; strip "Official Video", "New Mezmur", years, etc.). The same normalization makes search work with any keyboard. |
| `CloudLyricsRepository.kt`, `CloudLyric.kt` | Reference for Firestore structure, transactions, voting. |
| `data/*Entity.kt`, `*Dao.kt` | Reference for songs, playlists, favorites, recently played → redesign in Drift. |
| `MusicViewModel.kt` | Reference for player/lyrics state logic, shuffle, sleep timer. |
| `res/values-am`, `res/values-om` | Starting point for Amharic / Afaan Oromoo translations. |
| `future-work.md` | Reference for contribution + moderation roadmap. |
| Git history before 2026-09-14 | Contains the fuller UI (old `MainActivity.kt`, ~3,000 lines), e.g. library tabs and the sync editor. Also contains a committed signing keystore — don't reuse that key. |

## Core domain model (for the specsmd spec)

**Lyrics (shared, in the cloud)**
- **Song**: canonical text — title, transliteration, artist, album.
- **LyricSection**: verse / chorus / bridge, with lines; plus a **play order**.
- **Recording**: one performance of a song — artist/choir, source (YouTube video ID,
  Telegram file, local file), duration.
- **SyncTiming**: timestamps per line occurrence for one recording.
- **Contribution**: submitted lyrics / sync / recording link with status
  (pending / approved / needs changes / rejected) and moderator comment.

**Library (on the device)**
- **LocalTrack**: audio file from the device — path, folder, title, artist, album,
  duration, album art.
- **Folder** and **Album**: derived from LocalTrack paths and metadata.
- **Playlist** (user-created, ordered tracks) and **Favorite**.
- **SourceMatch**: remembered link from a detected source (video ID / local file /
  normalized title) to a recording, so users confirm only once.

**Account**
- **UserBackup**: favorites, playlists, source matches, overlay & app settings —
  restored after sign-in on a new phone.
