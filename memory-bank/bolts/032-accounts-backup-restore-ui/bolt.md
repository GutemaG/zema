---
id: 032-accounts-backup-restore-ui
unit: 002-accounts-backup-restore-ui
intent: 005-accounts-backup-restore
type: simple-construction-bolt
status: complete
stories:
  - 002-account-choice
  - 003-google-sign-in
created: '2026-10-29T19:05:45Z'
started: '2026-10-29T20:20:00Z'
completed: '2026-10-29T20:51:19Z'
current_stage: null
stages_completed:
  - name: plan
    completed: '2026-10-29T20:21:31Z'
    artifact: implementation-plan.md
  - name: implement
    completed: '2026-10-29T20:31:00Z'
    artifact: implementation-walkthrough.md
  - name: test
    completed: '2026-10-29T20:51:19Z'
    artifact: test-walkthrough.md
requires_bolts:
  - 031-accounts-backup-restore-ui
enables_bolts:
  - 033-accounts-backup-restore-ui
requires_units: []
blocks: false
complexity:
  avg_complexity: 2
  avg_uncertainty: 3
  max_dependencies: 2
  testing_scope: 3
---

# Bolt: 032-accounts-backup-restore-ui

## Overview

The one-time account choice and Google sign-in, hidden without client IDs.

## Stories Included

- [ ] **002-account-choice**: Account choice once (S04) - Priority: Must
- [ ] **003-google-sign-in**: Sign in with Google (S24) - Priority: Must

## Bolt Type

**Type**: Simple Construction Bolt
**Definition**: `.specsmd/aidlc/templates/construction/bolt-types/simple-construction-bolt.md`

## Stages

- [x] **1. plan**: Complete → implementation-plan.md
- [x] **2. implement**: Complete → source code + implementation-walkthrough.md
- [x] **3. test**: Complete → tests + test-walkthrough.md

## Dependencies

### Requires
- 031-accounts-backup-restore-ui

### Enables
- 033-accounts-backup-restore-ui

## Success Criteria

- [ ] All stories implemented
- [ ] All acceptance criteria met
- [ ] Analyze and format clean (Dart); `supabase test db` passes (backend)
- [ ] Tests passing locally
- [ ] Checked on the Android emulator (app bolts) or against the local backend (backend bolts)
- [ ] Key scan clean before commit
