---
id: 031-accounts-backup-restore-ui
unit: 002-accounts-backup-restore-ui
intent: 005-accounts-backup-restore
type: simple-construction-bolt
status: planned
stories:
  - 001-auth-repository
created: '2026-10-29T19:05:45Z'
started: null
completed: null
current_stage: null
stages_completed: []
requires_bolts:
  - 030-accounts-backend
enables_bolts:
  - 032-accounts-backup-restore-ui
requires_units:
  - 001-accounts-backend
blocks: false
complexity:
  avg_complexity: 2
  avg_uncertainty: 2
  max_dependencies: 2
  testing_scope: 2
---

# Bolt: 031-accounts-backup-restore-ui

## Overview

Auth and profile interfaces in zema_core, the Supabase versions in zema_data, the session in secure storage, and a fake.

## Stories Included

- [ ] **001-auth-repository**: Auth and profile repositories - Priority: Must

## Bolt Type

**Type**: Simple Construction Bolt
**Definition**: `.specsmd/aidlc/templates/construction/bolt-types/simple-construction-bolt.md`

## Stages

- [ ] **1. plan**: Pending → implementation-plan.md
- [ ] **2. implement**: Pending → source code + implementation-walkthrough.md
- [ ] **3. test**: Pending → tests + test-walkthrough.md

## Dependencies

### Requires
- 030-accounts-backend

### Enables
- 032-accounts-backup-restore-ui

## Success Criteria

- [ ] All stories implemented
- [ ] All acceptance criteria met
- [ ] Analyze and format clean (Dart); `supabase test db` passes (backend)
- [ ] Tests passing locally
- [ ] Checked on the Android emulator (app bolts) or against the local backend (backend bolts)
- [ ] Key scan clean before commit
