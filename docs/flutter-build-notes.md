# Zema — Flutter Build Notes

Technical notes for building the app in Flutter: what needs native Kotlin, which packages
to use, how the old LyricFlow repo maps over, and the core domain model.

## Can Kotlin be used in a Flutter app?

Yes. A Flutter app contains a normal Android project in `apps/mobile/android/`, and you can put
Kotlin code in `apps/mobile/android/app/src/main/kotlin/...`. Dart talks to it through **platform
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
