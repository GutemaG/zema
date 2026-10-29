---
id: 030-accounts-backend
unit: 001-accounts-backend
intent: 005-accounts-backup-restore
type: simple-construction-bolt
status: planned
stories:
  - 003-backups-table
  - 004-delete-account-function
created: '2026-10-29T19:05:45Z'
started: null
completed: null
current_stage: null
stages_completed: []
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

- [ ] **003-backups-table**: One private backup per user - Priority: Must
- [ ] **004-delete-account-function**: Delete account on the server - Priority: Must

## Bolt Type

**Type**: Simple Construction Bolt
**Definition**: `.specsmd/aidlc/templates/construction/bolt-types/simple-construction-bolt.md`

## Stages

- [ ] **1. plan**: Pending → implementation-plan.md
- [ ] **2. implement**: Pending → source code + implementation-walkthrough.md
- [ ] **3. test**: Pending → tests + test-walkthrough.md

## Dependencies

### Requires
- 029-accounts-backend

### Enables
- 031-accounts-backup-restore-ui

## Success Criteria

- [ ] All stories implemented
- [ ] All acceptance criteria met
- [ ] Analyze and format clean (Dart); `supabase test db` passes (backend)
- [ ] Tests passing locally
- [ ] Checked on the Android emulator (app bolts) or against the local backend (backend bolts)
- [ ] Key scan clean before commit
