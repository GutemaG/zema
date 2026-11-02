---
id: 052-contribution-and-sync-editor-ui
unit: 002-contribution-and-sync-editor-ui
intent: 006-contribution-and-sync-editor
type: simple-construction-bolt
status: complete
stories:
  - 014-edit-song-info
  - 015-backup-additions
created: '2026-11-02T07:00:52Z'
started: '2026-11-02T21:10:00Z'
completed: '2026-11-02T20:53:15Z'
current_stage: null
stages_completed:
  - name: plan
    completed: '2026-11-02T21:20:00Z'
    artifact: bolt.md
  - name: implement
    completed: '2026-11-02T22:30:00Z'
    artifact: bolt.md
  - name: test
    completed: '2026-11-02T23:55:00Z'
    artifact: bolt.md
requires_bolts:
  - 051-contribution-and-sync-editor-ui
enables_bolts: []
requires_units: []
blocks: false
complexity:
  avg_complexity: 2
  avg_uncertainty: 1
  max_dependencies: 1
  testing_scope: 2
---

# Bolt: 052-contribution-and-sync-editor-ui

## Overview

Edit song info S09 and backup additions.

## Stories Included

- [x] **014-edit-song-info**: Edit song info (S09) - Priority: Should
- [x] **015-backup-additions**: Backup additions: overrides and sync offsets - Priority: Could

## Bolt Type

**Type**: Simple Construction Bolt
**Definition**: `.specsmd/aidlc/templates/construction/bolt-types/simple-construction-bolt.md`

## Stages

- [x] **1. plan**: Complete → notes below (no separate docs, owner's request)
- [x] **2. implement**: Complete → source code
- [x] **3. test**: Complete → tests

## Dependencies

### Requires
- 051-contribution-and-sync-editor-ui

### Enables
- Intent 006 complete

## Success Criteria

- [x] All stories implemented
- [x] All acceptance criteria met
- [x] Analyze and format clean (Dart); no backend change
- [x] Tests passing locally (app 1,214, core 323)
- [x] Runs on the Android emulator (S09 by hand left to the owner)
- [x] Key scan clean before commit

## Notes

- `track_overrides` (schema v10): edits over the file's tags, applied in the library reads; `allTracks` stays raw for rescans, and backups identify tracks by their own tags.
- Covers come from the system photo picker (`image_picker`), copied into the app's files; they are not backed up.
- New backup sections `songInfo` (with the track inline, not an index) and `syncOffsets`; an older app keeps them as extras.
- A restore adds edits only where the song has none, and offsets only where the recording has none; edits for songs not found aren't kept.
