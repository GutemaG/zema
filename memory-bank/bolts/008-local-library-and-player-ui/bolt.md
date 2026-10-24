---
id: 008-local-library-and-player-ui
unit: 001-local-library-and-player-ui
intent: 002-local-library-and-player
type: simple-construction-bolt
status: planned
stories:
  - 018-track-multi-select
  - 019-play-history-and-auto-playlists
  - 020-library-settings
  - 021-playback-settings
created: 2026-10-24T19:23:00Z
started: null
completed: null
current_stage: null
stages_completed: []
requires_bolts:
  - 007-local-library-and-player-ui
enables_bolts: []
requires_units: []
blocks: false
complexity:
  avg_complexity: 2
  avg_uncertainty: 1
  max_dependencies: 2
  testing_scope: 3
---

# Bolt: 008-local-library-and-player-ui

## Overview

Close the intent: multi-select in Tracks, play history with the three auto playlists, and the Library and Playback sections in Settings. Then run the intent's "Done when" checks.

## Stories Included

- [ ] **018-track-multi-select**: Long-press selection and bulk actions - Priority: Must
- [ ] **019-play-history-and-auto-playlists**: Play counting, Recently added / Most played / Recently played - Priority: Must
- [ ] **020-library-settings**: Hidden folders and songs, rescan, min duration - Priority: Must
- [ ] **021-playback-settings**: Sleep timer default, unplug, interruptions, gapless - Priority: Must

## Bolt Type

**Type**: Simple Construction Bolt
**Definition**: `.specsmd/aidlc/templates/construction/bolt-types/simple-construction-bolt.md`

## Stages

- [ ] **1. plan**: Pending → implementation-plan.md
- [ ] **2. implement**: Pending → source code + implementation-walkthrough.md
- [ ] **3. test**: Pending → tests + test-walkthrough.md

## Expected Outputs

- Selection mode in Tracks
- Play events and auto playlist queries
- Settings Library and Playback sections
- Intent "Done when" checks: 1,000-track scan time, scrolling, restart persistence, background playback

## Dependencies

### Requires
- 007-local-library-and-player-ui

### Enables
- None in this intent (003-lyrics-engine-and-display builds on it)

## Success Criteria

- [ ] All stories implemented
- [ ] All acceptance criteria met
- [ ] `flutter analyze` clean, `dart format` clean
- [ ] Tests passing locally (CI once a GitHub remote exists)
- [ ] Checked on the Android emulator

## Notes

Closes intent 002. The 1,000-track timing and 30-minute background checks need a mid-range real phone; record them as open if none is available.
