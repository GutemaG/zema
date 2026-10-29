---
intent: 010-listen-to-identify
phase: inception
status: draft
created: 2026-10-29T08:29:54Z
updated: 2026-10-29T08:29:54Z
---

# Requirements: Listen to Identify

> Source: product owner request, 2026-10-29 (identify a song by listening, also in the
> background) · Complexity ★★★★★ · Needs 009 (fingerprints and lookup).

## Intent Overview

Identify a song playing nearby (another phone, a speaker, a church service) through the
microphone, and show its synced lyrics at the right line. The phone listens for a few
seconds, makes a noise-tolerant fingerprint on the phone, and asks the backend; the
answer includes the position in the recording, so lyrics start in sync. Listening is on
request, with an optional "keep listening" mode that the user turns on and that stops
by itself.

## Business Goals

| Goal | Success Metric | Priority |
|------|----------------|----------|
| Identify by listening | A catalog recording played from a speaker 2 m away is found within 10 s | Must |
| Lyrics in sync | Lyrics start at the right line, within ±0.5 s | Must |
| Trustworthy | No audio leaves the phone; the user always sees when the microphone is on | Must |

---

## Functional Requirements

### FR-1: Listen button
- **Description**: A "Listen" action (Home and Search) records up to ~10 s, fingerprints
  on the phone and looks it up (009 FR-3). Results: the song with "Show lyrics", "Not
  found" with "Try again", or "No internet" (the fingerprint is kept and looked up later).
- **Priority**: Must

### FR-2: Synced lyrics from listening
- **Description**: The match's position starts the lyrics at the right line, then a
  clock keeps them moving; a new listen re-syncs. View-only Now Playing (like 007 FR-6).
- **Priority**: Must

### FR-3: Keep listening
- **Description**: A mode the user switches on (e.g. for a service): listens in short
  bursts and follows song changes, shown by a persistent notification (Android foreground
  service with the microphone indicator). Stops after a chosen time (default 1 hour) or
  when the user stops it. iOS: only while Zema is open.
- **Priority**: Should

### FR-4: History
- **Description**: A list of identified songs with time; tap to open the song.
- **Priority**: Could

---

## Non-Functional Requirements

### Performance
| Requirement | Metric | Target |
|-------------|--------|--------|
| Time to result | Tap → song shown | < 10 s |
| Noise | Speech and room noise | Still found at normal listening volume (spike sets the bar) |

### Privacy
| Requirement | Standard | Notes |
|-------------|----------|-------|
| Audio | — | Never uploaded or saved; recordings are discarded after fingerprinting |
| Microphone | Platform indicators | Only on request or in "keep listening"; always visible |

### Battery
| Requirement | Metric | Target |
|-------------|--------|--------|
| Keep listening | Drain per hour | To measure; listens in bursts, not continuously |

---

## Constraints

### Technical Constraints

**Project-wide standards**: Required standards will be loaded from memory-bank standards folder by Construction Agent

**Intent-specific constraints**:
- Uses the noise-tolerant (peak-pair) fingerprint chosen in 009's spike.
- No always-on background listening: iOS does not allow it and app stores restrict it.
  "Keep listening" is started by the user and has an end time.

### Business Constraints
- Must be explained clearly in onboarding and store listings (microphone use).

---

## Assumptions

| Assumption | Risk if Invalid | Mitigation |
|------------|-----------------|------------|
| Phone microphones capture enough of the music in a hall or room | Low match rate | Spike with real recordings in a church/hall |
| Store review accepts user-started background listening | Feature removed on iOS | iOS keeps tap-to-listen only |

---

## Open Questions

| Question | Owner | Due Date | Resolution |
|----------|-------|----------|------------|
| Default length of "keep listening"? | Product owner | Requirements review | Pending |
| Identify songs not in the catalog (offer to contribute)? | Product owner | Requirements review | Pending |
