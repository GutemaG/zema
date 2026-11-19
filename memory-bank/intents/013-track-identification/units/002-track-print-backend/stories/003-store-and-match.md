---
id: 003-store-and-match
unit: 002-track-print-backend
intent: 013-track-identification
status: planned
priority: must
created: '2026-11-19T16:00:00Z'
assigned_bolt: 060-track-print-backend
implemented: false
---

# Story: 003-store-and-match

Store and match prints

**As a** listener
**I want** the server to tell me which song my file is
**So that** untagged files get lyrics

## Acceptance Criteria

- [ ] **Given** a migration, **When** applied, **Then** `track_prints` (song, version, print int[], keys int[], duration, status, installs) exists with an index on keys and RLS with no policies
- [ ] **Given** `match_track(version, print, duration, install_id)`, **When** called, **Then** published prints sharing keys are scored by differing bits and up to 3 songs under the threshold come back, best first
- [ ] **Given** too many calls, **When** over 300 a day per install or 2,000 per IP, **Then** HTTP 429, as `identify_audio`
- [ ] **Given** the seed tool, **When** run with the service key, **Then** it publishes prints for files with a song id
- [ ] **Given** 10,000 prints, **When** matched, **Then** < 300 ms on local Supabase
