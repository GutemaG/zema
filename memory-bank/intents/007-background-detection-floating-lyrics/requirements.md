---
intent: 007-background-detection-floating-lyrics
phase: inception
status: draft
created: 2026-10-23T22:16:40Z
updated: 2026-10-23T22:16:40Z
---

# Requirements: Background Detection and Floating Lyrics

> Source: `docs/roadmap.md` Stage 7 · screens: `docs/screens.md` S01–S03, S05 (Now detected),
> S27, S27s · native details: `docs/flutter-build-notes.md` · Complexity ★★★★★ · Native
> Kotlin required · **Spike first.**

## Intent Overview

Show lyrics in a floating window over YouTube, Telegram and other players — even when
Zema is closed — by detecting what's playing through Android media sessions. Android only.

## Business Goals

| Goal | Success Metric | Priority |
|------|----------------|----------|
| Lyrics over other apps | With Zema closed, a matched mezmur in YouTube opens floating lyrics within 3 s | Must |
| In sync | Within ±0.5 s | Must |
| Works on real devices | Verified on ≥ 2 phone brands | Must |

---

## Functional Requirements

### FR-0: Spike (before full build)
- **Description**: Throw-away prototype proving the Kotlin listener can open an overlay with the app process killed, on a real phone; decide Flutter (`flutter_overlay_window`) vs native Kotlin overlay UI.
- **Acceptance Criteria**: Decision recorded with evidence; can run any time after 001.
- **Priority**: Must

### FR-1: Playback detection (Kotlin)
- **Description**: `NotificationListenerService` + `MediaSessionManager.getActiveSessions()` read title, artist, duration, position, play state, package of enabled apps; events to Dart via `EventChannel` (JSON format in flutter-build-notes).
- **Priority**: Must

### FR-2: Matching
- **Description**: Order: remembered SourceMatch → exact recording (YouTube video ID / file) → fuzzy normalized title. Low confidence → "Is this the song?" (Yes / Choose another / Not a mezmur); answers remembered.
- **Priority**: Must

### FR-3: Floating lyrics overlay (S27)
- **Description**: States: bubble (draggable), compact bar (current + next line; expand, lock/click-through, close), expanded panel (resizable; font size, opacity, sync offset, "Open in Zema"), match confirmation, no lyrics (plain text / "Help sync it" / Dismiss). Follows play/pause/seek; hides after playback stops; remembers position, size, opacity; hidden while Zema is foreground (configurable).
- **Priority**: Must

### FR-4: Detection settings (S27s)
- **Description**: Master switch; apps to detect from; when to show (auto / ask first / on tap); appearance with live preview; matching options and "Clear remembered matches"; permission status with Fix buttons.
- **Priority**: Must

### FR-5: Onboarding (S01–S03)
- **Description**: Welcome with language choice; How it works (3 steps); Permissions setup with live status for music files, notification access, display over other apps; privacy note; Skip for now. iOS shows only music permission.
- **Priority**: Must

### FR-6: Now detected card (S05) and view-only Now Playing
- **Description**: Home card with source badge, title, artist, progress; "Show floating lyrics", "Open lyrics". S08/C01 in view-only mode following the other app's position.
- **Priority**: Must

### FR-7: OEM battery-saver guidance
- **Description**: Guide users through brand-specific battery settings so detection survives.
- **Priority**: Must

---

## Non-Functional Requirements

### Performance
| Requirement | Metric | Target |
|-------------|--------|--------|
| Time to overlay | Play start → overlay visible (Zema closed) | < 3 s |
| Sync accuracy | Overlay vs audio | ±0.5 s |

### Battery
| Requirement | Metric | Target |
|-------------|--------|--------|
| Detection | Mechanism | System callbacks only, no polling; no foreground work when nothing plays |

### Privacy
| Requirement | Standard | Notes |
|-------------|----------|-------|
| Notification data | — | Only media-session metadata; never notification text |

---

## Constraints

### Technical Constraints

**Project-wide standards**: Required standards will be loaded from memory-bank standards folder by Construction Agent

**Intent-specific constraints**:
- Android only; iOS cannot read other apps' playback or draw overlays.
- Reference old `FloatingLyricsService.kt` for native overlay window flags/drag/resize.

### Business Constraints
- Must work on mid/low-end phones (Tecno, Infinix, Samsung A-series) with aggressive battery savers.

---

## Assumptions

| Assumption | Risk if Invalid | Mitigation |
|------------|-----------------|------------|
| Notification listener stays bound while Zema is closed | Detection stops | Spike validates; battery guidance |
| YouTube/Telegram expose usable media sessions (title, position) | Can't match/sync | Spike checks both apps; fuzzy title matching |
| Overlay can be started from background on Android 10+ | Overlay blocked | `SYSTEM_ALERT_WINDOW` exemption; spike validates |

---

## Open Questions

| Question | Owner | Due Date | Resolution |
|----------|-------|----------|------------|
| **Overlay UI in Flutter (`flutter_overlay_window`) or native Kotlin?** (roadmap open decision #2) | Spike | End of spike | Pending |
| Which two phone brands are the acceptance devices? | Product owner | Before testing | Pending |
| Should onboarding (S01–S03) ship earlier than stage 7 (e.g. music permission in 002)? | Product owner | Requirements review | Pending |
