---
id: 030-accounts-backend
unit: 001-accounts-backend
intent: 005-accounts-backup-restore
type: simple-construction-bolt
status: complete
stories:
  - 003-backups-table
  - 004-delete-account-function
created: '2026-10-29T19:05:45Z'
started: '2026-10-29T19:26:59Z'
completed: '2026-10-29T19:33:58Z'
current_stage: null
stages_completed:
  - name: plan
    completed: '2026-10-29T19:27:59Z'
    artifact: implementation-plan.md
  - name: implement
    completed: '2026-10-29T19:29:48Z'
    artifact: implementation-walkthrough.md
  - name: test
    completed: '2026-10-29T19:33:58Z'
    artifact: test-walkthrough.md
requires_bolts:
  - 029-accounts-backend
enables_bolts:
  - 031-accounts-backup-restore-ui
requires_units: []
blocks: false
complexity:
  avg_complexity: 2
  avg_uncertainty: 1
  max_dependencies: 2
  testing_scope: 2
---

# Bolt: 030-accounts-backend

## Overview

The private backups table and the delete_account function.

## Stories Included

- [x] **003-backups-table**: One private backup per user - Priority: Must
- [x] **004-delete-account-function**: Delete account on the server - Priority: Must

## Bolt Type

**Type**: Simple Construction Bolt
**Definition**: `.specsmd/aidlc/templates/construction/bolt-types/simple-construction-bolt.md`

## Stages

- [x] **1. plan**: Complete → implementation-plan.md
- [x] **2. implement**: Complete → source code + implementation-walkthrough.md
- [x] **3. test**: Complete → tests + test-walkthrough.md

## Dependencies

### Requires
- 029-accounts-backend

### Enables
- 031-accounts-backup-restore-ui

## Success Criteria

- [x] All stories implemented
- [x] All acceptance criteria met
- [x] Analyze and format clean (Dart); `supabase test db` passes (backend)
- [x] Tests passing locally
- [x] Checked on the Android emulator (app bolts) or against the local backend (backend bolts)
- [x] Key scan clean before commit
