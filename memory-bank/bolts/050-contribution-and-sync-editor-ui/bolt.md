---
id: 050-contribution-and-sync-editor-ui
unit: 002-contribution-and-sync-editor-ui
intent: 006-contribution-and-sync-editor
type: simple-construction-bolt
status: complete
stories:
  - 012-my-contributions-and-badge
created: '2026-11-02T07:00:52Z'
started: '2026-11-02T19:00:00Z'
completed: '2026-11-02T19:23:56Z'
current_stage: null
stages_completed:
  - name: plan
    completed: '2026-11-02T19:10:00Z'
    artifact: bolt.md
  - name: implement
    completed: '2026-11-02T19:40:00Z'
    artifact: bolt.md
  - name: test
    completed: '2026-11-02T20:00:00Z'
    artifact: bolt.md
requires_bolts:
  - 049-contribution-and-sync-editor-ui
enables_bolts:
  - 051-contribution-and-sync-editor-ui
requires_units: []
blocks: false
complexity:
  avg_complexity: 2
  avg_uncertainty: 1
  max_dependencies: 1
  testing_scope: 2
---

# Bolt: 050-contribution-and-sync-editor-ui

## Overview

My contributions S23 and the status badge.

**Carried over from 045**: when a contribution is approved or rejected, delete Zema's copy of its shared audio file (story 006).

## Stories Included

- [x] **012-my-contributions-and-badge**: My contributions (S23) and the status badge - Priority: Must

## Bolt Type

**Type**: Simple Construction Bolt
**Definition**: `.specsmd/aidlc/templates/construction/bolt-types/simple-construction-bolt.md`

## Stages

- [x] **1. plan**: Complete → notes below (no separate docs, owner's request)
- [x] **2. implement**: Complete → source code
- [x] **3. test**: Complete → tests

## Dependencies

### Requires
- 049-contribution-and-sync-editor-ui

### Enables
- 051-contribution-and-sync-editor-ui

## Success Criteria

- [x] All stories implemented
- [x] All acceptance criteria met
- [x] Analyze and format clean (Dart); no backend change
- [x] Tests passing locally (app 1,188, core 322; 5/5 planted bugs caught)
- [ ] Checked on the Android emulator against the local backend (waits for the owner's sign-in)
- [x] Key scan clean before commit

## Notes

- The status check (`myContributionsProvider`) runs when the user is known, on resume and after a submit; it applies reviews to the own copies (approved: catalog version; rejected: back; shared audio deleted).
- New reviews are those after the last review seen (server time, per user in prefs); the first check on a phone tells nothing.
- Edit and resend: `resubmitDraft` (core) plus `ContributionDraft.resubmitId`; Submit calls `resubmit`. A recording or sync sent from another phone can't be edited here (no own copy).
- Fixed on the way: a review for a track no longer on the phone made reconcile throw; the link is skipped and the copy removed.
