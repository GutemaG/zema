---
id: 034-accounts-backup-restore-ui
unit: 002-accounts-backup-restore-ui
intent: 005-accounts-backup-restore
type: simple-construction-bolt
status: planned
stories:
  - 006-guest-prompt-and-entry-points
  - 007-backup-document
created: '2026-10-29T19:05:45Z'
started: null
completed: null
current_stage: null
stages_completed: []
requires_bolts:
  - 033-accounts-backup-restore-ui
enables_bolts:
  - 035-accounts-backup-restore-ui
requires_units: []
blocks: false
complexity:
  avg_complexity: 2
  avg_uncertainty: 1
  max_dependencies: 2
  testing_scope: 2
---

# Bolt: 034-accounts-backup-restore-ui

## Overview

C09 and the sign-in entry points; the versioned backup document and track identity in zema_core.

## Stories Included

- [ ] **006-guest-prompt-and-entry-points**: Guest sign-in prompt (C09) and entry points - Priority: Must
- [ ] **007-backup-document**: Versioned backup document - Priority: Must

## Bolt Type

**Type**: Simple Construction Bolt
**Definition**: `.specsmd/aidlc/templates/construction/bolt-types/simple-construction-bolt.md`

## Stages

- [ ] **1. plan**: Pending → implementation-plan.md
- [ ] **2. implement**: Pending → source code + implementation-walkthrough.md
- [ ] **3. test**: Pending → tests + test-walkthrough.md

## Dependencies

### Requires
- 033-accounts-backup-restore-ui

### Enables
- 035-accounts-backup-restore-ui

## Success Criteria

- [ ] All stories implemented
- [ ] All acceptance criteria met
- [ ] Analyze and format clean (Dart); `supabase test db` passes (backend)
- [ ] Tests passing locally
- [ ] Checked on the Android emulator (app bolts) or against the local backend (backend bolts)
- [ ] Key scan clean before commit
