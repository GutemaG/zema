---
id: 037-accounts-backup-restore-ui
unit: 002-accounts-backup-restore-ui
intent: 005-accounts-backup-restore
type: simple-construction-bolt
status: planned
stories:
  - 010-relink-and-merge
created: '2026-10-29T19:05:45Z'
started: null
completed: null
current_stage: null
stages_completed: []
requires_bolts:
  - 036-accounts-backup-restore-ui
enables_bolts:
  - 038-accounts-backup-restore-ui
requires_units: []
blocks: false
complexity:
  avg_complexity: 3
  avg_uncertainty: 2
  max_dependencies: 2
  testing_scope: 2
---

# Bolt: 037-accounts-backup-restore-ui

## Overview

Track matcher and the merge into Drift in one transaction.

## Stories Included

- [ ] **010-relink-and-merge**: Re-link tracks and merge - Priority: Must

## Bolt Type

**Type**: Simple Construction Bolt
**Definition**: `.specsmd/aidlc/templates/construction/bolt-types/simple-construction-bolt.md`

## Stages

- [ ] **1. plan**: Pending → implementation-plan.md
- [ ] **2. implement**: Pending → source code + implementation-walkthrough.md
- [ ] **3. test**: Pending → tests + test-walkthrough.md

## Dependencies

### Requires
- 036-accounts-backup-restore-ui

### Enables
- 038-accounts-backup-restore-ui

## Success Criteria

- [ ] All stories implemented
- [ ] All acceptance criteria met
- [ ] Analyze and format clean (Dart); `supabase test db` passes (backend)
- [ ] Tests passing locally
- [ ] Checked on the Android emulator (app bolts) or against the local backend (backend bolts)
- [ ] Key scan clean before commit
