---
intent: 011-share-lyrics-clips
phase: inception
status: draft
created: 2026-10-29T15:44:10Z
updated: 2026-10-29T15:44:10Z
---

# Requirements: Share Lyrics Clips

> Source: product owner request, 2026-10-29 (share part of a song with its lyrics to
> TikTok, YouTube, Snapchat and others) · Complexity ★★★★ · Native or FFmpeg encoding
> (spike decides) · Needs 002 (player) and 003 (synced lyrics) · **Spike first.**

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

### FR-0: Spike (before full build)
- **Description**: Throw-away prototype that makes one 60 s 1080×1920 MP4 (H.264 + AAC)
  from a local file and its synced lyrics, on a real Android phone and on iOS. Compare a
  maintained FFmpeg build with native encoding (AVFoundation on iOS, MediaCodec and
  MediaMuxer on Android): app size, render time, memory, licence.
- **Acceptance Criteria**: Decision recorded with evidence (render time for 60 s on a
  mid-range Android phone, added app size).
- **Priority**: Must

### FR-1: Pick the clip
- **Description**: A "Share clip" action (Now Playing, Song detail, song menu C03) opens a
  clip editor for a library track linked to lyrics: start and end handles on the song's
  timeline, the lyric lines under it, and Play to hear the selection. Handles can snap to
  the start of a lyric line. The length is capped (default 60 s; 2 min allowed).
- **Acceptance Criteria**: The selection can't exceed the cap or the track; the preview
  plays exactly the selected part.
- **Priority**: Must

### FR-2: Choose the look
- **Description**: A small set of layouts: cover art (or a letter tile) with a blurred
  background, the current line large and the next line dimmed, in the Night Vigil
  palette. Options: transliteration on or off, and the Zema mark.
- **Priority**: Must (one layout); Should (more layouts)

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
| App size | Added by the encoder | To measure in the spike; prefer native if FFmpeg adds > 20 MB |

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
- Android and iOS.
- Only local library files: the catalog has no audio, so a track must be linked to its
  song to share synced lyrics.
- `ffmpeg_kit_flutter` was retired in 2025; any FFmpeg build used must be maintained
  and its licence (LGPL/GPL) acceptable for the store app.
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
| Cap at 60 s or 2 min by default? | Product owner | Requirements review | Pending (proposed: 60 s default, 2 min allowed) |
| Is the Zema mark on by default, and can it be turned off? | Product owner | Requirements review | Pending |
| Include a link to the song in the share text (needs a public web page)? | Product owner | Requirements review | Pending |
| Build before or after 005 (accounts)? | Product owner | Requirements review | Pending (no dependency on 005) |
