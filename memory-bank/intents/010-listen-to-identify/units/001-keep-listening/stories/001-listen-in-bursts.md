---
id: 001-listen-in-bursts
unit: 001-keep-listening
intent: 010-listen-to-identify
status: complete
priority: must
created: '2026-11-20T12:00:00Z'
assigned_bolt: 063-keep-listening
implemented: true
---

# Story: 001-listen-in-bursts

**As a** listener at a service
**I want** Zema to keep identifying songs once I start it
**So that** each song's lyrics follow without tapping Listen

## Acceptance Criteria

- [x] **Given** it's started for 30 min, 1 h or 2 h, **When** songs play, **Then** it listens in bursts: 15 s after a match (sooner near the song's end), backing off 10, 20, 30 s after misses
- [x] **Given** the same song at the expected place, **Then** nothing changes; at another place it re-syncs; another song switches the lyrics
- [x] **Given** bursts, **Then** the found song stays on screen, and History gets one entry per song
- [x] **Given** the time limit, Stop, or the microphone failing twice, **Then** it ends and says why
