---
id: 038-accounts-backup-restore-ui
unit: 002-accounts-backup-restore-ui
intent: 005-accounts-backup-restore
type: simple-construction-bolt
status: planned
stories:
  - 011-restore-screen
  - 012-unmatched-entries-kept
created: '2026-10-29T19:05:45Z'
started: null
completed: null
current_stage: null
stages_completed: []
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

- [ ] **011-restore-screen**: Restore on a new phone (S26) - Priority: Must
- [ ] **012-unmatched-entries-kept**: Songs not found are kept - Priority: Should

## Bolt Type

**Type**: Simple Construction Bolt
**Definition**: `.specsmd/aidlc/templates/construction/bolt-types/simple-construction-bolt.md`

## Stages

- [ ] **1. plan**: Pending → implementation-plan.md
- [ ] **2. implement**: Pending → source code + implementation-walkthrough.md
- [ ] **3. test**: Pending → tests + test-walkthrough.md

## Dependencies

### Requires
- 037-accounts-backup-restore-ui

### Enables
- Intent 006

## Success Criteria

- [ ] All stories implemented
- [ ] All acceptance criteria met
- [ ] Analyze and format clean (Dart); `supabase test db` passes (backend)
- [ ] Tests passing locally
- [ ] Checked on the Android emulator (app bolts) or against the local backend (backend bolts)
- [ ] Key scan clean before commit
