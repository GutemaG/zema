---
intent: 011-share-lyrics-clips
phase: inception
status: approved
created: 2026-10-29T15:44:10Z
updated: 2026-11-20T18:00:00Z
---

# Requirements: Share Lyrics Clips

> Source: product owner request, 2026-10-29 (share part of a song with its lyrics to
> TikTok, YouTube, Snapchat and others) · Complexity ★★★★ · Android first, native encoding
> (MediaCodec + MediaMuxer, no FFmpeg) · Needs 002 (player) and 003 (synced lyrics) · **Encoder first.**

## Intent Overview

Let the user pick part of a song in their library, up to 1 minute (or 2), and turn it
into a portrait video with the lyrics highlighted in time over the cover art. The video
is made on the phone and shared through the phone's share menu to TikTok, YouTube
Shorts, Snapchat, Instagram, WhatsApp, Telegram or any other app.

## Business Goals

| Goal | Success Metric | Priority |
|------|----------------|----------|
| Share a moment of a song | From Now Playing, a 60 s clip with synced lyrics is ready to share in under 2 minutes of the user's time | Must |
| Looks right everywhere | The video plays and shows Ethiopic and Latin lyrics correctly in TikTok, YouTube Shorts and Snapchat | Must |
| Lyrics in sync | Each line lights up within ±0.2 s of the audio in the video | Must |
| Spreads the app | The video carries a small "Zema" mark | Should |

---

## Functional Requirements

### FR-0: Encoder first
- **Description**: The native Android encoder (MediaCodec + MediaMuxer) is built first
  and timed on the owner's phone before the editor is built on it.
- **Acceptance Criteria**: A 60 s 1080×1920 clip renders in under 30 s on the owner's
  phone, or the encoder falls back to 720×1280; the time is recorded in the bolt.
- **Priority**: Must

### FR-1: Pick the clip
- **Description**: A "Share clip" action (Now Playing, Song detail, song menu C03) opens a
  clip editor for a library track linked to lyrics: start and end handles on the song's
  timeline, the lyric lines under it, and Play to hear the selection. Handles can snap to
  the start of a lyric line. The selection starts at 60 s and can be stretched to 2 min.
- **Acceptance Criteria**: The selection can't exceed the cap or the track; the preview
  plays exactly the selected part.
- **Priority**: Must

### FR-2: Choose the look
- **Description**: One layout: the current line large and the next line dimmed. Every
  choice below has a default, so a clip can be made without touching any of them, and
  the editor shows a live preview:
  - **Background**: the cover art blurred (default), a photo from the gallery, or a
    plain colour (Night Vigil by default).
  - **Transparency**: how much the background is dimmed behind the text (default 40 %).
  - **Text**: size (default medium), colour (default white) and position (default
    centre); transliteration on or off (default off).
  - **Song details**: title (on), artist name (on) and album name (off), shown at the
    top; each can be edited for the clip only.
  - **Pictures**: the album picture (default the cover art, or a gallery photo) and an
    artist picture (none by default; a gallery photo), shown small next to the names.
  - **Zema mark**: on by default, can be turned off.
  - The last choices (except photos and edited names) become the defaults for the
    next clip.
- **Priority**: Must (defaults and preview); Should (the rest)

### FR-3: Make the video
- **Description**: Cut the selected audio from the user's file and render the lyric
  frames on the phone (drawn by Flutter, one picture per line change), then encode them
  with the audio to MP4. Shows progress and can be cancelled. Works offline. Nothing is
  uploaded.
- **Acceptance Criteria**: Output is 1080×1920, 30 fps, H.264 + AAC; the clip length and
  lyric timing match the selection.
- **Priority**: Must

### FR-4: Share
- **Description**: The finished video goes to the phone's share menu, with an option to
  save it to the gallery. Temporary files are deleted afterwards.
- **Priority**: Must

### FR-5: Songs without synced lyrics
- **Description**: For text-only lyrics, the video shows the chosen lines as a static
  page (or the user picks the lines to show).
- **Priority**: Should

### FR-6: Lyrics-only video
- **Description**: A video with the lyrics and a plain background and no song audio,
  for platforms that mute copyrighted music.
- **Priority**: Could

---

## Non-Functional Requirements

### Performance
| Requirement | Metric | Target |
|-------------|--------|--------|
| Render time | 60 s clip, mid-range Android phone | < 30 s (the spike sets the bar) |
| Memory | Peak during render | No crash on a 3 GB RAM phone |
| App size | Added by the encoder | ~0 (native) |

### Privacy
| Requirement | Standard | Notes |
|-------------|----------|-------|
| Audio | — | Clips are made on the phone; nothing is uploaded by Zema |

### Accessibility and localization
| Requirement | Standard | Notes |
|-------------|----------|-------|
| Editor | App standards | Handles usable with a screen reader and at 1.3× text |
| Video text | — | Ethiopic text renders with Noto Sans Ethiopic, never as boxes |

---

## Constraints

### Technical Constraints

**Project-wide standards**: Required standards will be loaded from memory-bank standards folder by Construction Agent

**Intent-specific constraints**:
- Android first. iOS (AVFoundation) is a later intent; the encoder sits behind a Dart
  interface so iOS can plug in.
- Only local library files: the catalog has no audio, so a track needs lyrics of its own
  to share: linked to a catalog song, waiting for review, or saved on this phone only.
- No FFmpeg: `ffmpeg_kit_flutter` was retired in 2025, and native encoding adds no app
  size or licence questions.
- Sharing uses the system share menu; app-specific SDKs (TikTok Share Kit, Snapchat
  Creative Kit) need developer accounts and are out of scope for now.

### Business Constraints
- Copyright: the user shares their own copy of a recording; the share screen shows a
  short note that platforms may mute or remove copyrighted music.

---

## Assumptions

| Assumption | Risk if Invalid | Mitigation |
|------------|-----------------|------------|
| Flutter can draw lyric frames to images fast enough | Slow renders | One frame per line change, not 30 per second |
| Phones encode 1080×1920 H.264 in hardware | Slow renders on cheap phones | Fall back to 720×1280 |
| Platforms accept the MP4 from the share menu | Upload fails | Test each platform in the spike |

---

## Open Questions

| Question | Owner | Due Date | Resolution |
|----------|-------|----------|------------|
| Cap at 60 s or 2 min by default? | Product owner | 2026-11-20 | 60 s default, up to 2 min |
| Is the Zema mark on by default, and can it be turned off? | Product owner | 2026-11-20 | On by default, can be turned off |
| Include a link to the song in the share text? | Product owner | 2026-11-20 | No link for now: title and artist only |
| Which platforms? | Product owner | 2026-11-20 | Android first; iOS later |
