---
intent: 009-audio-fingerprint-library
phase: inception
status: draft
created: 2026-10-29T08:29:54Z
updated: 2026-10-29T08:29:54Z
---

# Requirements: Audio Fingerprints for the Library

> Source: product owner request, 2026-10-29 (identify songs by their sound, not only by
> their tags) · Complexity ★★★★☆ · Needs the backend (004) and contributions (006).

## Intent Overview

Identify the songs in the phone's library by their audio, not only by their title tags.
Every recording in the catalog gets an audio fingerprint; the app fingerprints the
library's files in the background and asks the backend which recording each one is, and
where its audio starts. This links files with missing or wrong tags, and picks the right
recording's timing (studio vs live), so synced lyrics stop drifting.

Only fingerprints are stored and sent, never audio. A fingerprint cannot be turned back
into sound.

## Business Goals

| Goal | Success Metric | Priority |
|------|----------------|----------|
| Link files with bad tags | A catalog recording renamed "Track 01" with no tags links to its song | Must |
| Right timing for the right recording | A file of a catalog recording uses that recording's timing, in sync within ±0.5 s | Must |
| No audio leaves the phone | Only fingerprints are uploaded (checked in tests) | Must |

---

## Functional Requirements

### FR-0: Spike (before full build)
- **Description**: Throw-away prototype comparing fingerprint methods on real mezmur
  files: a whole-file method (Chromaprint-style) and a peak-pair method (Shazam-style,
  shared with 010). Measures accuracy, fingerprint size, time per song on a mid-range
  phone, and whether one method can serve both 009 and 010.
- **Acceptance Criteria**: Decision recorded with numbers.
- **Priority**: Must

### FR-1: Fingerprint module in `zema_core`
- **Description**: Pure-Dart fingerprinting (decoded PCM in, fingerprint out) and
  matching, used by the app, the seed tool and the backend lookup, so all sides agree
  (same approach as the generated search rules). No GPL/LGPL code linked into the app.
- **Priority**: Must

### FR-2: Fingerprints in the catalog
- **Description**: A fingerprint per recording, stored with the recording; recording
  versions bump when it changes. The seed tool fingerprints seed audio locally and stores
  only the fingerprint. Contributors (006) fingerprint their file on the phone and submit
  the fingerprint with the recording.
- **Priority**: Must

### FR-3: Lookup
- **Description**: A backend function takes a fingerprint and returns the best matching
  approved recording, a confidence, and the offset between the file and the recording.
  Rate-limited like reports.
- **Priority**: Must

### FR-4: Background library identification
- **Description**: The app fingerprints library files that are not identified yet,
  in the background (charging and on Wi-Fi by default), and looks them up. Results are
  remembered per file; a manual link always wins over a fingerprint match, and a
  fingerprint match wins over a title match.
- **Priority**: Must

### FR-5: Settings and status
- **Description**: A switch for audio identification, "only while charging", progress
  ("312 of 1,040 songs checked"), and "Identify this song" on a track's menu.
- **Priority**: Should

---

## Non-Functional Requirements

### Performance
| Requirement | Metric | Target |
|-------------|--------|--------|
| Fingerprinting | Time per 4-minute song, mid-range phone | < 2 s (to confirm in the spike) |
| Fingerprint size | Per recording | < 100 KB |
| Lookup | Server response | < 1 s |

### Privacy
| Requirement | Standard | Notes |
|-------------|----------|-------|
| Audio | — | Never uploaded or stored on the server; only fingerprints |

### Battery
| Requirement | Metric | Target |
|-------------|--------|--------|
| Background work | When it runs | Charging (default) and with spare battery; pauses otherwise |

---

## Constraints

### Technical Constraints

**Project-wide standards**: Required standards will be loaded from memory-bank standards folder by Construction Agent

**Intent-specific constraints**:
- Fingerprinting code is shared Dart in `zema_core`; native code only if the spike shows
  Dart is too slow, and then behind the same interface.
- Uses the catalog and recordings from 004; catalog fingerprints come from the seed and
  from contributions (006).

### Business Constraints
- The catalog holds only fingerprints; nobody's audio is collected.

---

## Assumptions

| Assumption | Risk if Invalid | Mitigation |
|------------|-----------------|------------|
| Dart is fast enough to fingerprint on the phone | Slow, battery-heavy | Spike measures; native fallback behind the same interface |
| Contributors have the audio file for the recordings they add | Few fingerprints in the catalog | Fingerprint from any file the contributor plays in Zema |
| One method can serve files and microphone (010) | Two fingerprints per recording | Spike decides; storing two is acceptable |

---

## Open Questions

| Question | Owner | Due Date | Resolution |
|----------|-------|----------|------------|
| Which fingerprint method (or both)? | Spike | End of spike | Pending |
| Should 009 come before or after 007? | Product owner | Requirements review | Pending |
