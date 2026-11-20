---
id: 005-identify-by-print
unit: 003-track-print-app
intent: 013-track-identification
status: complete
priority: must
created: '2026-11-19T16:00:00Z'
assigned_bolt: 061-track-print-app
implemented: true
---

# Story: 005-identify-by-print

Identify by print

**As a** listener
**I want** a file with no link to be identified when I play it
**So that** I see its lyrics

## Acceptance Criteria

- [x] **Given** a track with no manual, sound or title link, **When** played or reached by the background scan, **Then** it is printed (first 110 s) and looked up with `match_track`
- [x] **Given** a match, **When** it comes back, **Then** the track links to that song (order: manual → sound → title → print) and the print is kept on the phone
- [x] **Given** no network, **When** printed, **Then** the lookup waits until online; one lookup per file and print version
- [x] **Given** a wrong print link, **When** the user unlinks, **Then** it is marked no-lyrics and not looked up again
