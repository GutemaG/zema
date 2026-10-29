---
id: 031-accounts-backup-restore-ui
unit: 002-accounts-backup-restore-ui
intent: 005-accounts-backup-restore
type: simple-construction-bolt
status: complete
stories:
  - 001-auth-repository
created: '2026-10-29T19:05:45Z'
started: '2026-10-29T19:34:10Z'
completed: '2026-10-29T19:59:08Z'
current_stage: null
stages_completed:
  - name: plan
    completed: '2026-10-29T19:39:26Z'
    artifact: implementation-plan.md
  - name: implement
    completed: '2026-10-29T19:59:08Z'
    artifact: implementation-walkthrough.md
  - name: test
    completed: '2026-10-29T19:59:08Z'
    artifact: test-walkthrough.md
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

- [x] **001-auth-repository**: Auth and profile repositories - Priority: Must

## Bolt Type

**Type**: Simple Construction Bolt
**Definition**: `.specsmd/aidlc/templates/construction/bolt-types/simple-construction-bolt.md`

## Stages

- [x] **1. plan**: Complete → implementation-plan.md
- [x] **2. implement**: Complete → source code + implementation-walkthrough.md
- [x] **3. test**: Complete → tests + test-walkthrough.md

## Dependencies

### Requires
- 030-accounts-backend

### Enables
- 032-accounts-backup-restore-ui

## Success Criteria

- [x] All stories implemented
- [x] All acceptance criteria met
- [x] Analyze and format clean (Dart); `supabase test db` passes (backend)
- [x] Tests passing locally
- [x] Checked on the Android emulator (app bolts) or against the local backend (backend bolts)
- [x] Key scan clean before commit
