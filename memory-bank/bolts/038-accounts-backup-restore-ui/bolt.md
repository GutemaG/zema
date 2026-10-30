---
id: 038-accounts-backup-restore-ui
unit: 002-accounts-backup-restore-ui
intent: 005-accounts-backup-restore
type: simple-construction-bolt
status: complete
stories:
  - 011-restore-screen
  - 012-unmatched-entries-kept
created: '2026-10-29T19:05:45Z'
started: '2026-10-30T12:17:00Z'
completed: '2026-10-30T12:58:04Z'
current_stage: null
stages_completed:
  - name: plan
    completed: '2026-10-30T12:18:00Z'
    artifact: implementation-plan.md
  - name: implement
    completed: '2026-10-30T12:35:00Z'
    artifact: implementation-walkthrough.md
  - name: test
    completed: '2026-10-30T12:58:04Z'
    artifact: test-walkthrough.md
requires_bolts:
  - 037-accounts-backup-restore-ui
enables_bolts: []
requires_units: []
blocks: false
complexity:
  avg_complexity: 2
  avg_uncertainty: 2
  max_dependencies: 2
  testing_scope: 3
---

# Bolt: 038-accounts-backup-restore-ui

## Overview

Restore screen after sign-in; unmatched entries kept and re-tried after rescans (Drift v7); intent done-when checks.

## Stories Included

- [x] **011-restore-screen**: Restore on a new phone (S26) - Priority: Must
- [x] **012-unmatched-entries-kept**: Songs not found are kept - Priority: Should

## Bolt Type

**Type**: Simple Construction Bolt
**Definition**: `.specsmd/aidlc/templates/construction/bolt-types/simple-construction-bolt.md`

## Stages

- [x] **1. plan**: Complete → implementation-plan.md
- [x] **2. implement**: Complete → source code + implementation-walkthrough.md
- [x] **3. test**: Complete → tests + test-walkthrough.md

## Dependencies

### Requires
- 037-accounts-backup-restore-ui

### Enables
- Intent 006

## Success Criteria

- [x] All stories implemented
- [ ] All acceptance criteria met: all but the end-to-end emulator restore (story 011)
- [x] Analyze and format clean (Dart); `supabase test db` passes (backend)
- [x] Tests passing locally
- [ ] Checked on the Android emulator (app bolts) or against the local backend (backend bolts): S26 opened after sign-in; the end-to-end restore was skipped at the owner's request (see test-walkthrough.md)
- [x] Key scan clean before commit
