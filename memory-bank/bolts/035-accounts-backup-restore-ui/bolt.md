---
id: 035-accounts-backup-restore-ui
unit: 002-accounts-backup-restore-ui
intent: 005-accounts-backup-restore
type: simple-construction-bolt
status: complete
stories:
  - 008-backup-now
created: '2026-10-29T19:05:45Z'
started: '2026-10-30T11:28:00Z'
completed: '2026-10-30T11:41:30Z'
current_stage: null
stages_completed:
  - name: plan
    completed: '2026-10-30T11:29:00Z'
    artifact: implementation-plan.md
  - name: implement
    completed: '2026-10-30T11:33:00Z'
    artifact: implementation-walkthrough.md
  - name: test
    completed: '2026-10-30T11:41:30Z'
    artifact: test-walkthrough.md
requires_bolts:
  - 034-accounts-backup-restore-ui
enables_bolts:
  - 036-accounts-backup-restore-ui
requires_units: []
blocks: false
complexity:
  avg_complexity: 2
  avg_uncertainty: 1
  max_dependencies: 2
  testing_scope: 3
---

# Bolt: 035-accounts-backup-restore-ui

## Overview

Backup & sync screen with Back up now.

## Stories Included

- [x] **008-backup-now**: Back up now (S25b) - Priority: Must

## Bolt Type

**Type**: Simple Construction Bolt
**Definition**: `.specsmd/aidlc/templates/construction/bolt-types/simple-construction-bolt.md`

## Stages

- [x] **1. plan**: Complete → implementation-plan.md
- [x] **2. implement**: Complete → source code + implementation-walkthrough.md
- [x] **3. test**: Complete → tests + test-walkthrough.md

## Dependencies

### Requires
- 034-accounts-backup-restore-ui

### Enables
- 036-accounts-backup-restore-ui

## Success Criteria

- [x] All stories implemented
- [x] All acceptance criteria met
- [x] Analyze and format clean (Dart); `supabase test db` passes (backend)
- [x] Tests passing locally
- [x] Checked on the Android emulator (app bolts) or against the local backend (backend bolts)
- [x] Key scan clean before commit
