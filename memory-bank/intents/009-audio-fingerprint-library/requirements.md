---
intent: 009-audio-fingerprint-library
phase: construction
status: in-progress
created: 2026-10-29T08:29:54Z
updated: 2026-11-12T12:30:00Z
---

# Requirements: Song Detection, Identification and Floating Lyrics

> Source: product owner requests, 2026-10-29 and 2026-11-03 ("identify the song after it
> has been playing for any length of time, like Musixmatch or Google Pixel"; "merge 007
> and 009, they are related") · screens: `docs/screens.md` S01–S03, S05 (Now detected),
> S27, S27s · native details: `docs/flutter-build-notes.md` · Complexity ★★★★★ · Native
> Kotlin required · Needs the backend (004) and contributions (006) · **Two spikes
> first.**
>
> Intent 007 (background detection and floating lyrics) was merged into this intent on
> 2026-11-03. Its requirements are Part B below.

## Intent Overview

Zema knows which song is playing, wherever it plays, and shows its lyrics at the line
being sung now.

- **Part A, identify by sound.** From a few seconds of audio taken at any point in a
  song, Zema finds the song, the catalog recording, and the position in it.
  - **Sources**: the microphone (another phone, a speaker, a church service), or a file
    on the phone with missing or wrong tags.
  - **Online or offline**: it works with or without internet, using an index kept on the
    phone, as Pixel's Now Playing does.
  - **Quick start**: Listen can be started from the app, from a lock-screen control, or
    from a home-screen widget.
- **Part B, detect other apps (Android).** Zema reads what YouTube, Telegram and other
  players are playing from Android's media sessions. It shows synced lyrics in a
  floating window over them, even when Zema is closed.

The two parts meet in three places:

- **Detection falls back to listening.** When a detected song can't be matched by its
  title, the user can identify it by listening.
- **One floating window.** A song found by listening can be shown in the same floating
  window.
- **One view-only Now playing.** Both parts use the same view-only Now playing, which
  follows a song that Zema doesn't play itself.

**How identification works.** Every catalog recording gets an audio fingerprint: hashes
of pairs of spectral peaks, each with its time in the recording. The phone fingerprints
the excerpt itself and compares only hashes, either with its offline index or with the
server. A match is the recording whose hashes line up with the excerpt at one consistent
time shift, and that shift is the position.

Audio never leaves the phone. Only fingerprints are stored and sent, and a fingerprint
can't be turned back into sound.

Listening is always started by the user. Hands-free "keep listening" stays in 010, which
builds on this intent.

## Business Goals

| Goal | Success Metric | Priority |
|------|----------------|----------|
| Identify by listening, from any point | A catalog recording played from a speaker 2 m away, starting anywhere in the song, is found within 10 s | Must |
| Identify offline | The same test in airplane mode finds songs that are in the phone's offline index | Must |
| Lyrics at the right line | After a match, the highlighted line is within ±0.5 s of the audio | Must |
| Lyrics over other apps | With Zema closed, a matched mezmur in YouTube opens floating lyrics within 3 s, within ±0.5 s | Must |
| Link files with bad tags | A catalog recording renamed "Track 01" with no tags links to its song and uses that recording's timing | Must |
| Few wrong answers | Fewer than 1 in 100 lookups of songs not in the catalog return a song | Must |
| No audio leaves the phone | Only fingerprints are uploaded (checked in tests) | Must |
| Works on real devices | Verified on the owner's phone and a Samsung A-series phone | Must |

---

## Decisions (2026-11-03)

| Question | Decision |
|----------|----------|
| Merge 007 and 009? | **Yes.** Built together, since both lead to the same lyrics view and floating window. |
| Order with 007 | Merged, so no order is needed. The two spikes (FR-0, FR-11) run first, in parallel. |
| Can Listen work offline? | **Yes, Must.** The phone keeps a compact offline index (FR-4). Online lookup is used when offline finds nothing. |
| Lock screen and home screen | **Yes, Must.** Android: a Quick Settings tile (usable from the lock screen) and a home-screen widget. iOS: a Control Center / lock-screen control and a home-screen widget. Each opens a compact Listen screen (FR-6). |
| Fingerprints from users' libraries | **Yes, opt-in, asked once.** Only for files linked to a catalog recording that has no fingerprint. They are published automatically when two devices agree, otherwise after a moderator approves (FR-2). |
| Floating window UI | Spike decides: Flutter (`flutter_overlay_window`) or native Kotlin (FR-11). |
| Acceptance phones | The owner's phone and one Samsung A-series. A Tecno or Infinix phone if one is available. |
| Onboarding (S01–S03) | Ships with this intent, including the microphone permission. |
| Third-party recognition (Shazam, ACRCloud and similar) | **Not used.** Most catalog songs aren't in their databases, the lyrics need the position in Zema's own recording, and offline must work. |

---

## FR-0 spike results (2026-11-03, first pass on the computer)

Peak-pair fingerprint in pure Dart, on the 11 test songs: mezmur and Ethiopian
contemporary songs, 3–6 minutes each. Excerpts were taken at the intro, 25%, 50%, 75%
and the last 12 s, with 3, 5, 8 and 10 s lengths.

The microphone was simulated with:

- band-limiting,
- hall reverb (RT60 0.6–1.5 s),
- pink noise,
- reversed music as babble, at 10, 5 and 0 dB SNR.

**Settings tested** (11,025 Hz mono, 1,024-sample FFT, 23 ms hop):

| Index | Peaks/s | Pairs per peak | Hashes/s | Size per 5-min song (6 B/hash) |
|-------|---------|----------------|----------|--------------------------------|
| Server | 20 | 5 | 98 | ~170 KB |
| Offline | 10 | 2 | 20 | ~34 KB |

The query side is the same for both: 20 peaks/s and 10 pairs per peak, about 1,850
hashes for 10 s.

**Accuracy** (correct song above the threshold):

| Condition | Server, 3 s | Server, 5 s | Server, 10 s | Offline, 5 s | Offline, 10 s |
|-----------|-------------|-------------|--------------|--------------|---------------|
| Clean excerpt | 100% | 100% | 100% | 100% | 100% |
| Re-encoded at 48 kbps AAC | 100% | 100% | 100% | 98% | 100% |
| Room, 10 dB | 100% | 100% | 100% | 96% | 98% |
| Hall with babble, 5 dB | 98% | 98% | 100% | 93% | 98% |
| Hall with babble, 0 dB | 95% | 100% | 100% | 82% | 93% |
| Speed +1% / +2%, with the query speed sweep | 100% | 100% | 100% | 100% | 100% |

**Other measurements**:

- **Wrong answers**: none. The highest score for songs left out of the index was 7, and
  the threshold is 12 aligned hashes.
- **Position error**: ±0.02 s (p95).
- **Speed**: the Mac runs the fingerprint in 12 ms for 10 s and 0.29 s for a 4-minute
  song (Dart AOT). Estimated 4–6× slower on a mid-range phone, which is within the NFR.

**Decisions**:

- Peak-pair fingerprint, in pure Dart. No native code is needed.
- **Two densities**: the server and offline indexes store fewer pairs than the query
  makes, so one query works against both.
- **Speed sweep**: the query is also tried at 0.98, 0.99, 1.01 and 1.02 speed. Without
  it, a +1% speed change (common in re-uploads) drops to 2–78%.
- **Threshold**: at least 12 hashes aligned at one time shift. It is to be re-checked
  against a large catalog, together with a "best vs runner-up" ratio.

**Findings that change the design**:

- **Repeated sections**: a chorus that repeats can match at the wrong repeat (seen as
  2–3 minute position errors in a few short excerpts). FR-7 must use the offset with the
  most votes, keep listening when two offsets are close, and Re-sync must correct it.
- **Server storage**: Postgres stores about 40 B per row, not 6, so hashes must not be
  one row each. Postings are packed per hash (bytea), or held by an edge function as an
  in-memory index.

**Still to do**:

- A real microphone test on the phone (quiet room, talking, a hall).
- Timing on a mid-range phone.
- The false-match check at catalog scale.

---

## FR-11 spike results (2026-11-13, emulator, Android 16)

Prototype: commit `c50adf8`, `android/app/src/debug/kotlin/.../spike/` (removed in FR-12;
the overlay there is a starting point for FR-14). A `NotificationListenerService` reads every active media session and logs
each change in the `docs/flutter-build-notes.md` event format (logcat tag `ZemaSpike`
and `files/spike_events.jsonl`); a plain native overlay shows the title and a live
position.

**What YouTube exposes** (`com.google.android.youtube`): title, artist (the channel
name), duration, position with its update time, speed, and play state (buffering,
playing, paused). **No video ID**: media ID and media URI are empty, so matching a
YouTube source falls back to title and channel (FR-13 step 2 needs another source for
the ID, or none).

**After the process is killed** (`kill -9`, as the low-memory killer does):

| Measure | Result |
|---------|--------|
| System restarts Zema's process for the listener | ~1 s after the kill, no app opened |
| Listener connected after process start (profile build) | 0.4–3.9 s |
| Overlay added (native view) | 34–130 ms (1.7 s in a debug build) |
| Third kill in a row | restarted after ~40 s: the system backs off |

**Memory (PSS)**:

| Process | PSS |
|---------|-----|
| Zema with only the listener and the native overlay | ~61 MB |
| Zema with only a Flutter engine (the lock-screen Listen) | ~124 MB |
| A second Flutter engine added to the running app | +4 MB |

**Other findings**:
- Android hides other apps' overlays over some system screens (Settings, permission
  dialogs: `mIsForceHiddenNonSystemOverlayWindow`). The overlay comes back by itself
  after.
- A force-stopped app stays stopped: its tile isn't delivered until the app is opened
  again. Expected to apply to the listener too (not measured).

**Decision: native Kotlin overlay UI.** It starts in well under a second from a killed
process and costs half the memory of a Flutter engine, which matters on the low-end
phones Zema targets. Dart still owns matching and lyrics; how the service gets them
(a timing cache written by Dart, or a headless engine started on a song change) is
decided in FR-12/FR-13.

**Still to check on a real phone**: Telegram (not on the emulator), YouTube Music, a
Pixel or an OEM phone with a battery saver killing the process, and whether YouTube's
notification carries the video ID.

## Build progress (2026-11-12)

Part A works offline against the songs on the phone. The catalog side (server index and
online lookup) and Part B are not started.

| FR | State | What exists, what's left |
|----|-------|--------------------------|
| FR-0 Fingerprint spike | Done | Results above; `packages/zema_core/tool/fingerprint_eval.dart`. Timing on a mid-range phone not yet measured. |
| FR-1 Engine in `zema_core` | Done | `Fingerprinter`, `FingerprintIndex`, `AudioFingerprint` (versioned), with tests. |
| FR-2 Fingerprints in the catalog | Not started | Needs the backend. |
| FR-3 Online lookup | Not started | Needs FR-2. |
| FR-4 Offline index | Partly | Every library song is fingerprinted on the phone (Kotlin decoder, saved in Drift, searched in a worker isolate). Left: catalog recordings, favorites, budget setting, Wi-Fi updates. |
| FR-5 Listen | Done offline | Listen from Home, Search, and Now playing when nothing is playing: permission, listening state, checkpoints at 3/6/10 s, found / not found / failed. Left, with other FRs: server lookup and the offline queue (FR-3), "Show floating lyrics" (FR-14). |
| FR-6 Lock screen and home screen | Done on Android | Quick Settings tile "Identify song" and a home-screen widget (mic button, last song identified, tap for History). Both open a compact Listen over the lock screen that starts at once; "Open in Zema" asks to unlock and opens the result in the app. Left: iOS Control Center control and widget. |
| FR-7 Synced lyrics from a match | Done for library songs | Show lyrics follows the music by clock, Re-sync, end of song → Listen again, plain lyrics when not synced, Play on this phone from the matched place. An unsure place (repeated chorus) is flagged. Left: share the view with FR-15; file offset from FR-8. |
| FR-8 Identify library files | Not started | Library songs are fingerprinted, but not yet matched to catalog recordings. |
| FR-9 History | Done | Opened from Listen and from the widget; newest first with date and time; tap plays the song; remove one or clear all; the same song again within 10 minutes stays one entry; kept on the phone only (schema v12). |
| FR-10 Song not in the catalog | Done | Not found offers "Add this song", which starts a lyrics draft without a recording (not over the lock screen). |
| FR-11 Detection and overlay spike | Done on the emulator | Results above; decision: native Kotlin overlay. Left: Telegram and a real phone. |
| FR-12 Playback detection | Done (Android) | `MediaWatchService` → `PlaybackHub` → `zema/detection` channels → `detectedPlaybacksProvider` / `currentDetectionProvider`. Default apps: YouTube, YouTube Music, Telegram, Telegram X. Checked on the emulator: play, pause, already playing at app start, access turned off. Nothing shows it yet (FR-15). |
| FR-13 Matching a detected song | Done, without the prompt UI | `detectedSongProvider`: remembered answer (keyed by app + normalized title and artist, or media ID), then the title against the catalog index on the phone (`SongMatcher.rank` / `chooseDetectedSong`; a one-word title needs the artist to be sure). Answers: Yes / Choose another (`confirm`), Not a mezmur, Identify by listening (`listeningForProvider`: the Listen result is remembered with its offset). Step 2 (exact recording) only by media ID: YouTube gives none and recordings aren't indexed by video ID. The "Is this the song?" prompt is drawn in FR-14 and FR-15. |
| FR-14 Floating lyrics | Steps 1–3 of 5 done | Native window (`LyricsOverlay`): bubble, bar (current and next line; lock lets touches through at 80% opacity, an Android rule), panel (all lines, text size, opacity, timing ±0.5 s, Open in Zema, resize). Follows the source app's play, pause and seek from `PlaybackHub`; remembers position, size, opacity and text size. While Zema runs, `lyricsOverlaySyncProvider` sends a sure match's lines, timed by the song's first recording (as the player does); a timing change is remembered for the video, Close hides it until another song, Open in Zema opens the song (S07). While Zema is closed, `OverlayEngine` runs `overlayMain` in a headless engine (JNI plugins only: shared_preferences and audio_service keep one registration per process, and audio_service starts the full app) while an enabled app plays; it stops 2 min after playback stops, or when Zema starts. |
| FR-15 – FR-18 (Part B) | Not started | |

Known gaps in what's built: files below 11,025 Hz decode wrongly (the Kotlin resampler
can't upsample); microphone delay and MP3/AAC priming aren't corrected (under 0.1 s).

## Functional Requirements

## Part A: Identify by sound

### FR-0: Fingerprint spike (before the full build)
- **Description**: A throw-away prototype of a peak-pair ("landmark", Shazam-style)
  fingerprint, tested on real mezmur and other catalog songs, both as file excerpts and
  as microphone recordings in a quiet room, in a room with talking, and in a hall.
- **Acceptance Criteria**: A decision is recorded with numbers for:
  - Accuracy against excerpt length (3, 5, 8 and 10 s) and start position (intro, verse,
    chorus, last 10 s).
  - Position accuracy.
  - False matches on songs that aren't in the catalog.
  - Hashes per second, and size per recording for the full server index and for the
    compact offline index.
  - Time to fingerprint 10 s and a whole 4-minute song on a mid-range Android phone, in
    Dart. If Dart is too slow, the native fallback is measured too.
  - The tuning that follows from these: sample rate, window, peak density, fan-out and
    match threshold.
- **Priority**: Must

### FR-1: Fingerprint engine in `zema_core`
- **Description**: Pure-Dart code that takes decoded mono PCM and returns hashes, each
  with its time offset. Matching (the time-shift vote) is in the same package and is
  used both on the phone (the offline index) and to define the server's lookup. The app,
  the seed tool and the tests use the same code. The engine has a version number, and
  fingerprints made with another version are never compared.
- **Acceptance Criteria**:
  - The same audio gives the same hashes on every platform.
  - An excerpt cut from any point of a file matches that file at the right position,
    within ±50 ms.
  - Matching still works after volume changes, MP3/AAC re-encoding, and up to ±2% speed
    change. Speed tolerance is to be confirmed in the spike.
  - No GPL or LGPL code is linked into the app.
- **Priority**: Must

### FR-2: Fingerprints in the catalog
- **Description**: Each approved recording has a fingerprint in the server index: its
  hashes and their times, the engine version, and the recording's duration.
- **Acceptance Criteria**:
  - **Seed tool**: fingerprints the owner's audio files locally and uploads only the
    hashes.
  - **Contributions (006)**: the recording step fingerprints the linked file on the
    phone and sends the fingerprint with the contribution. It is public only after a
    moderator approves it.
  - **From users' libraries** (opt-in, asked once, can be changed in Settings): when a
    library file is linked (by hand or by title) to a catalog recording that has no
    fingerprint, the app sends the file's fingerprint as a pending fingerprint. It is
    published automatically when a second device sends one that aligns with it for the
    same recording. Otherwise a moderator approves it from the review queue.
  - **Updates**: a recording's version goes up when its fingerprint changes, and phones
    see the change (004 caching, and the offline index in FR-4).
  - **New engine version**: the owner can rebuild the index from stored files with the
    seed tool, while the old index keeps answering until the new one is complete.
  - Recordings without a fingerprint still work everywhere else. They just can't be
    identified by sound.
- **Priority**: Must

### FR-3: Online lookup
- **Description**: A backend function takes hashes (each with its time in the excerpt)
  and the engine version, and returns the matches above the threshold, best first, up to
  3. Each match has the song, the recording, a confidence, and the position in the
  recording where the excerpt starts. When nothing passes the threshold, it returns "no
  match".
- **Acceptance Criteria**:
  - Guests can use it.
  - It is rate-limited per device and per IP, like reports.
  - A query is not stored or linked to an account. Only counts are kept, for rate limits
    and match-rate statistics.
  - Only approved recordings are matched.
- **Priority**: Must

### FR-4: Offline index on the phone
- **Description**: The phone keeps a compact fingerprint index and matches against it
  without the network. It holds, in this order, until the storage budget is used:
  1. Recordings linked to songs in the library.
  2. Favorites.
  3. The catalog's most identified and most played recordings.
- **Acceptance Criteria**:
  - **Updates**: on Wi-Fi by default, in the background, and only what changed (by
    recording version).
  - **Lookup order**: Listen checks the offline index first and asks the server only
    when nothing is found and the phone is online.
  - **Budget**: 50 MB by default, adjustable (25 / 50 / 100 MB, or "Library only").
    Settings shows how many songs it covers.
  - **Same results**: the same excerpt gives the same match and position offline as
    online, for recordings in both.
- **Priority**: Must

### FR-5: Listen (identify through the microphone)
- **Description**: A Listen button on Home, on Search, and on Now playing when nothing is
  playing. It records from the microphone and fingerprints while recording. It tries the
  offline index, then the server, after about 3 s, 6 s and 10 s, and stops as soon as a
  match is confident. Each piece of audio is thrown away once it has been fingerprinted.
- **Acceptance Criteria**:
  - **Permission**: the first time, the microphone permission is asked with a reason. If
    it is refused, a screen explains how to turn it on in system settings.
  - **While listening**: a full-screen state with an animation, a visible "Listening…"
    and Cancel. The platform's microphone indicator is on only during this state.
  - **Song found**: the song's title, artist and artwork, "Show lyrics", "Show floating
    lyrics" (Android), and "Play on this phone" when the song is in the library.
  - **Not found**: "Couldn't identify this song", with Try again and tips (move closer,
    less noise).
  - **Offline and not in the offline index**: the fingerprint is kept and looked up when
    the phone is back online. The result appears in History (FR-9) with an in-app
    notice.
  - Works the same whether the song has been playing for 5 s or 4 minutes.
- **Priority**: Must

### FR-6: Quick start from the lock screen and home screen
- **Description**: Listen can start without first opening the app. Each entry opens a
  compact Listen screen (FR-5) that can show over the lock screen. The result needs
  unlocking only to open the full app.
  - **Android**: a Quick Settings tile ("Identify song"), usable from the lock screen,
    and a home-screen widget with a Listen button and the last song identified.
  - **iOS**: a Control Center / lock-screen control and a home-screen widget. Both open
    Zema straight into Listen, because iOS widgets can't record by themselves.
- **Acceptance Criteria**:
  - From the locked phone, tile → result in the same time as FR-5.
  - The microphone starts only after the user's tap.
  - Works offline (FR-4).
- **Priority**: Must

### FR-7: Synced lyrics from a match
- **Description**: "Show lyrics" opens the lyrics at the current line. The start position
  is the match position, plus the excerpt length, plus the time since the excerpt ended.
  A clock then moves the lyrics on. The view is view-only Now playing (shared with
  FR-15): the same lyrics view without player controls.
- **Acceptance Criteria**:
  - The highlighted line is within ±0.5 s of the audio.
  - **Re-sync**: listens again and corrects the position.
  - **End of the recording**: the view ends with "Listen again" for the next song.
  - **Not synced yet**: when the matched recording has lyrics but no timing, the plain
    lyrics show.
  - **Play on this phone**: plays the library file from the matched position, after
    adjusting for the file's own offset (FR-8).
- **Priority**: Must

### FR-8: Identify files in the library
- **Description**: The app fingerprints files that aren't identified yet. By default it
  does this in the background, while the phone is charging and has battery to spare. It
  matches them with the offline index first and then the server, using a few excerpts
  from inside each file, so a file that is cut short or has an extra intro still
  matches.
- **Acceptance Criteria**:
  - **What the result gives**: the file is linked to the song and recording, and the
    lyrics use that recording's timing. The time shift between the file and the
    recording is applied, so files with an extra intro, silence, or a missing start
    stay in sync.
  - **Order of trust**: a manual link always wins over a fingerprint match, and a
    fingerprint match wins over a title match.
  - **Remembering**: results are remembered per file and redone only when the file
    changes.
  - **On request**: "Identify this song" on a track's menu runs it straight away.
- **Priority**: Must

### FR-9: History
- **Description**: A list of songs identified by Listen, with date and time, kept on the
  phone. Tap opens the song. Items can be deleted one by one, or all at once. The
  home-screen widget shows the latest one.
- **Priority**: Should

### FR-10: Song not in the catalog
- **Description**: When Listen finds nothing, the result offers "Add this song", which
  starts a contribution draft (006) without a recording.
- **Priority**: Could

## Part B: Detect other apps and floating lyrics (Android)

### FR-11: Detection and overlay spike (before the full build)
- **Description**: A throw-away prototype, on a real phone, proving that the Kotlin
  listener can open an overlay while the app process is killed.
- **Acceptance Criteria**:
  - Decides between Flutter (`flutter_overlay_window`) and a native Kotlin overlay UI.
  - Checks that YouTube and Telegram expose a usable title and position.
  - The decision is recorded with evidence.
- **Priority**: Must

### FR-12: Playback detection (Kotlin)
- **Description**: `NotificationListenerService` plus
  `MediaSessionManager.getActiveSessions()` read the title, artist, duration, position,
  play state and package of the enabled apps. Events go to Dart through an
  `EventChannel`, in the JSON format given in `docs/flutter-build-notes.md`.
- **Priority**: Must

### FR-13: Matching a detected song
- **Description**: Matches are tried in this order:
  1. A remembered match.
  2. The exact recording (YouTube video ID, or the file).
  3. A fuzzy match on the normalized title.
- **Acceptance Criteria**:
  - **Low confidence**: asks "Is this the song?", with Yes, Choose another, Identify by
    listening (FR-5) and Not a mezmur. Answers are remembered.
  - **Listening fallback**: a match found by listening is remembered for that source
    (for example the YouTube video ID). Its position also corrects the lyrics' offset
    for that source.
- **Priority**: Must

### FR-14: Floating lyrics window (S27)
- **Description**: The window has these states:
  - **Bubble**: draggable.
  - **Compact bar**: the current and next line; expand, lock / click-through, close.
  - **Expanded panel**: resizable; font size, opacity, sync offset, "Open in Zema".
  - **Match confirmation**: asks whether the detected song is right (FR-13).
  - **No lyrics**: plain text, "Help sync it", or Dismiss.
- **Acceptance Criteria**:
  - **Following playback**: follows the detected app's play, pause and seek. For a
    Listen match, it follows the match clock with Re-sync.
  - **Showing and hiding**: hides after playback stops. Hidden while Zema is in the
    foreground (configurable).
  - **Remembered**: position, size and opacity.
- **Priority**: Must

### FR-15: Now detected card (S05) and view-only Now playing
- **Description**: A Home card with a source badge (YouTube, Telegram, Listen), title,
  artist and progress, plus "Show floating lyrics" and "Open lyrics". Now playing
  (S08/C01) has a view-only mode that follows the other app's position, or the Listen
  match clock (FR-7).
- **Priority**: Must

### FR-16: Settings (S27s)
- **Description**: One screen for detection and identification:
  - **Detection**: master switch, the apps to detect from, and when to show (auto / ask
    first / on tap).
  - **Appearance**: with a live preview.
  - **Matching**: options, and "Clear remembered matches".
  - **Identification**: identify library songs by sound, only while charging, the
    offline index budget and its coverage, share fingerprints (FR-2), and clear Listen
    history.
  - **Permissions**: status, with Fix buttons.
  - **Privacy**: a line explaining that only fingerprints leave the phone.
- **Priority**: Must

### FR-17: Onboarding (S01–S03)
- **Description**:
  - **Welcome**: language choice.
  - **How it works**: 3 steps.
  - **Permissions setup**: live status for music files, microphone, notification access
    and display over other apps, with a privacy note and "Skip for now".
  - **iOS**: only music and microphone.
- **Priority**: Must

### FR-18: OEM battery-saver guidance
- **Description**: Guides users through brand-specific battery settings, so detection
  and the offline index updates survive.
- **Priority**: Must

---

## Non-Functional Requirements

### Performance
| Requirement | Metric | Target |
|-------------|--------|--------|
| Time to result | Tap Listen → song shown, offline index or 4G | Median < 5 s, p90 < 10 s |
| Excerpt length | Shortest that identifies a song | 5 s in a quiet room; 10 s with talking or room echo |
| Accuracy (files) | 5 s excerpts from catalog recordings | ≥ 98% (spike confirms) |
| Accuracy (microphone) | 10 s at normal volume, 2 m from a speaker | ≥ 85% (spike confirms) |
| Wrong answers | Lookups of songs not in the catalog that return a song | < 1% |
| Position | Match position against the real position | ±0.5 s at the lyrics |
| Fingerprinting on the phone | 10 s excerpt / whole 4-minute file, mid-range phone | < 0.5 s / < 3 s |
| Offline match | Search of a 50 MB index on the phone | < 1 s |
| Upload | Per online lookup | < 20 KB |
| Online lookup | Server time at 10,000 recordings | p95 < 1 s |
| Time to overlay | Play starts in another app → overlay visible, Zema closed | < 3 s |
| Overlay sync | Overlay against the audio | ±0.5 s |

### Scalability
| Requirement | Metric | Target |
|-------------|--------|--------|
| Server index size | Per 5-minute recording | < 200 KB (spike confirms) |
| Offline index size | Per 5-minute recording | < 30 KB, so 50 MB covers about 1,500 recordings (spike confirms) |
| Catalog | Recordings the lookup handles within the targets | 10,000 now; 100,000 without a redesign |

### Privacy and Security
| Requirement | Standard | Notes |
|-------------|----------|-------|
| Audio | — | Never uploaded, saved or logged. Microphone buffers are discarded after fingerprinting |
| Microphone | Platform indicators and permission | Used only while a Listen screen shows, and started only by a tap. Never in the background in this intent |
| Queries | — | Not stored or linked to an account. Rate-limited |
| Notification data | — | Only media-session metadata is read, never notification text |
| Catalog writes | Row-level security (004/006) | Fingerprints are published only by approval, two-device agreement, or the owner's seed tool |

### Battery
| Requirement | Metric | Target |
|-------------|--------|--------|
| Library identification and offline index updates | When they run | Charging (default) and with spare battery, on Wi-Fi. Paused otherwise |
| Detection | Mechanism | System callbacks only, no polling. No foreground work when nothing plays |

---

## Constraints

### Technical Constraints

**Project-wide standards**: Required standards will be loaded from memory-bank standards folder by Construction Agent

**Intent-specific constraints**:
- **Shared engine**: fingerprinting and matching are shared Dart in `zema_core`. Native
  code is used only if the spike shows Dart is too slow, and then behind the same
  interface.
- **Server**: the server stores and matches hashes and never decodes audio. Matching
  runs in Postgres (an indexed hash table and a time-shift vote) or in an edge function,
  whichever the spike finds fast enough.
- **Platforms**:
  - Detection and the floating window are Android only, because iOS can't read other
    apps' playback or draw over them.
  - Listen, the offline index and the widgets work on both platforms.
- **Android microphone rules**: on Android 14+, the microphone may be used only from a
  visible activity started by the user. The tile and widget therefore open the compact
  Listen activity (it may show over the lock screen); they don't record from a
  background service.
- **Reference code**: the old `FloatingLyricsService.kt`, for the native overlay window
  flags, drag and resize.
- **Dependencies**: 003 (lyrics and matching) and 004 (catalog, recordings). Catalog
  fingerprints come from the seed tool, contributions (006), and opted-in libraries.

### Business Constraints
- The catalog holds only fingerprints. Nobody's audio is collected.
- Microphone use and notification access are explained in onboarding and in the store
  listings.
- It must work on mid- and low-end phones (Tecno, Infinix, Samsung A-series) that have
  aggressive battery savers.

---

## Assumptions

| Assumption | Risk if Invalid | Mitigation |
|------------|-----------------|------------|
| A peak-pair fingerprint identifies mezmur from microphone audio in halls with echo | Low match rate in churches | Spike records in a real hall; longer excerpts; tune peak density |
| Dart is fast enough on the phone | Slow Listen, heavy battery use | Spike measures; native fallback behind the same interface |
| A compact offline index keeps accuracy | Offline matches fail | Spike compares full and compact indexes; raise the budget or keep fewer, denser songs |
| Enough catalog recordings get fingerprints | Listen rarely finds anything | Seed tool, contributions, and opted-in library fingerprints |
| Postgres can match within 1 s at 10,000 recordings | Slow online lookups | Edge function with an in-memory index, or a table partitioned by hash |
| The notification listener stays bound while Zema is closed | Detection stops | Spike validates; battery guidance (FR-18) |
| YouTube and Telegram expose usable media sessions | No match or sync from them | Spike checks both; title matching; listening fallback |
| An overlay can start from the background on Android 10+ | Overlay blocked | `SYSTEM_ALERT_WINDOW` exemption; spike validates |

---

## Open Questions

None. All were resolved on 2026-11-03 (see Decisions). The spikes (FR-0, FR-11) fill
in the numbers marked "spike confirms".
