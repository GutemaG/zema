---
id: 051-contribution-and-sync-editor-ui
unit: 002-contribution-and-sync-editor-ui
intent: 006-contribution-and-sync-editor
type: simple-construction-bolt
status: complete
stories:
  - 013-moderator-queue
created: '2026-11-02T07:00:52Z'
started: '2026-11-02T20:10:00Z'
completed: '2026-11-02T19:31:59Z'
current_stage: null
stages_completed:
  - name: plan
    completed: '2026-11-02T20:15:00Z'
    artifact: bolt.md
  - name: implement
    completed: '2026-11-02T20:40:00Z'
    artifact: bolt.md
  - name: test
    completed: '2026-11-02T21:00:00Z'
    artifact: bolt.md
requires_bolts:
  - 050-contribution-and-sync-editor-ui
enables_bolts:
  - 052-contribution-and-sync-editor-ui
requires_units: []
blocks: false
complexity:
  avg_complexity: 2
  avg_uncertainty: 2
  max_dependencies: 2
  testing_scope: 3
---

# Bolt: 051-contribution-and-sync-editor-ui

## Overview

Moderator queue S23m and the intent's end-to-end check.

## Stories Included

- [x] **013-moderator-queue**: Moderator review queue (S23m) - Priority: Must

## Bolt Type

**Type**: Simple Construction Bolt
**Definition**: `.specsmd/aidlc/templates/construction/bolt-types/simple-construction-bolt.md`

## Stages

- [x] **1. plan**: Complete → notes below (no separate docs, owner's request)
- [x] **2. implement**: Complete → source code
- [x] **3. test**: Complete → tests

## Dependencies

### Requires
- 050-contribution-and-sync-editor-ui

### Enables
- 052-contribution-and-sync-editor-ui

## Success Criteria

- [x] All stories implemented
- [ ] All acceptance criteria met (the intent's end-to-end emulator check is open)
- [x] Analyze and format clean (Dart); no backend change
- [x] Tests passing locally (app 1,197; 6/6 planted bugs caught)
- [ ] Checked on the Android emulator against the local backend (needs sign-in and a moderator account)
- [x] Key scan clean before commit

## Notes

- S23m (`/review-queue`) and its item (`/review-queue/item?id=`); entries on S05 and Profile only for moderators (`isModeratorProvider`, from the profile's roles).
- The kind filter works on the fetched queue; the count is of what is shown.
- YouTube opens through `url_launcher` (new dependency; Android `<queries>` for https VIEW).
- The sync preview is silent: a 100 ms timer lights up `lineAt(starts, position)`.
- `SongLines` was split out of S22 so S23m shows lyrics the same way.
