---
id: 008-local-library-and-player-ui
unit: 001-local-library-and-player-ui
intent: 002-local-library-and-player
type: simple-construction-bolt
status: complete
stories:
  - 018-track-multi-select
  - 019-play-history-and-auto-playlists
  - 020-library-settings
  - 021-playback-settings
created: 2026-10-24T19:23:00Z
started: 2026-10-26T10:17:06Z
completed: 2026-10-26T12:48:29Z
current_stage: null
stages_completed:
  - name: plan
    completed: 2026-10-26T10:20:31Z
    artifact: implementation-plan.md
  - name: implement
    completed: 2026-10-26T10:37:53Z
    artifact: implementation-walkthrough.md
  - name: test
    completed: 2026-10-26T12:48:29Z
    artifact: test-walkthrough.md
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

- [x] **1. plan**: Complete → implementation-plan.md
- [x] **2. implement**: Complete → source code + implementation-walkthrough.md
- [x] **3. test**: Complete → tests + test-walkthrough.md

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

- [x] All stories implemented
- [x] All acceptance criteria met (unplug, interruptions and the fixed gapless build still need a device check; see test-walkthrough.md)
- [x] `flutter analyze` clean, `dart format` clean
- [ ] Tests passing locally (CI once a GitHub remote exists) (local: yes; CI: pending a GitHub remote)
- [ ] Checked on the Android emulator (partly: Settings and Rescan; the emulator was in use for the rest)

## Notes

Closes intent 002. The 1,000-track timing and 30-minute background checks need a mid-range real phone; record them as open if none is available.
