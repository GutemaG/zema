---
id: 002-track-print
unit: 001-track-print-core
intent: 013-track-identification
status: complete
priority: must
created: '2026-11-19T16:00:00Z'
assigned_bolt: 059-track-print-core
implemented: true
---

# Story: 002-track-print

Track print

**As a** developer
**I want** a small fingerprint of a whole file and a way to compare two
**So that** copies of one recording can be found by sound

## Acceptance Criteria

- [x] **Given** decoded audio, **When** printed, **Then** the first 110 s give 32-bit values, ≤ 10 KB, with `trackPrintVersion` and the duration
- [x] **Given** two prints, **When** compared, **Then** the share of differing bits over the best shift (±2 s) comes back, plus the index keys of a print
- [x] **Given** the eval on the owner's music folder, **When** run with re-encodes (320/128/64 kbps MP3, 128 kbps AAC), trims of 0.3–2 s and every different-song pair, **Then** a threshold separates all of them, with the margins written down
- [x] (not needed: the eval passed) **Given** the eval fails, **When** reviewed, **Then** the intent stops for a decision (fallback: landmark windows)
- [x] **Given** a mid phone, **When** printing a decoded song, **Then** it takes < 1 s
