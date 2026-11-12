---
intent: 010-listen-to-identify
phase: inception
status: draft
created: 2026-10-29T08:29:54Z
updated: 2026-11-12T12:30:00Z
---

# Requirements: Listen to Identify

> Source: product owner request, 2026-10-29 (identify a song by listening, also in the
> background) · Complexity ★★★★★ · Needs 009 (fingerprints and lookup).

## Intent Overview

Keep identifying songs through the microphone without the user tapping Listen each
time, for example during a service. Builds on 009, which already provides tap-to-listen,
lookup from any point in the song, synced lyrics from a match, and History. This intent
adds a "keep listening" mode that follows song changes and ends by itself.

> Scope change 2026-11-03: the Listen button, synced lyrics from a match and History
> moved to 009 (FR-4, FR-5, FR-7).

> Plan for FR-1 and FR-2, and how they compare with Pixel's Now Playing:
> `keep-listening-plan.md` (2026-11-12).

## Business Goals

| Goal | Success Metric | Priority |
|------|----------------|----------|
| Follow a service hands-free | Each new song in a 1-hour playlist is shown within 15 s of starting | Must |
| Trustworthy | No audio leaves the phone; the user always sees when the microphone is on | Must |

---

## Functional Requirements

### FR-1: Keep listening
- **Description**: A mode the user switches on (e.g. for a service): listens in short
  bursts with 009's engine and follows song changes, shown by a persistent notification
  (Android foreground service with the microphone indicator). Stops after a chosen time
  (default 1 hour) or when the user stops it. iOS: only while Zema is open.
- **Priority**: Must

### FR-2: Follow song changes
- **Description**: While keep listening is on, the view-only lyrics (009 FR-5) switch
  to the new song when it changes, and re-sync if the position drifts.
- **Priority**: Must

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
- Uses 009's fingerprint engine and lookup.
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
