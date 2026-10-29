---
id: 029-accounts-backend
unit: 001-accounts-backend
intent: 005-accounts-backup-restore
type: simple-construction-bolt
status: complete
stories:
  - 001-profiles-and-roles
  - 002-google-auth-config
created: '2026-10-29T19:05:45Z'
started: '2026-10-29T19:10:38Z'
completed: '2026-10-29T19:26:21Z'
current_stage: null
stages_completed:
  - name: plan
    completed: '2026-10-29T19:18:50Z'
    artifact: implementation-plan.md
  - name: implement
    completed: '2026-10-29T19:22:57Z'
    artifact: implementation-walkthrough.md
  - name: test
    completed: '2026-10-29T19:26:20Z'
    artifact: test-walkthrough.md
requires_bolts: []
enables_bolts:
  - 030-accounts-backend
requires_units: []
blocks: false
complexity:
  avg_complexity: 2
  avg_uncertainty: 1
  max_dependencies: 2
  testing_scope: 2
---

# Bolt: 029-accounts-backend

## Overview

Profiles and roles on sign-up; Google provider in the local config, and the setup guide.

## Stories Included

- [x] **001-profiles-and-roles**: Profiles made on sign-up, with roles - Priority: Must
- [x] **002-google-auth-config**: Google provider config and setup guide - Priority: Must

## Bolt Type

**Type**: Simple Construction Bolt
**Definition**: `.specsmd/aidlc/templates/construction/bolt-types/simple-construction-bolt.md`

## Stages

- [x] **1. plan**: Complete → implementation-plan.md
- [x] **2. implement**: Complete → source code + implementation-walkthrough.md
- [x] **3. test**: Complete → tests + test-walkthrough.md

## Dependencies

### Requires
- Intent 004 (complete)

### Enables
- 030-accounts-backend

## Success Criteria

- [x] All stories implemented
- [x] All acceptance criteria met
- [x] Analyze and format clean (Dart); `supabase test db` passes (backend)
- [x] Tests passing locally
- [x] Checked on the Android emulator (app bolts) or against the local backend (backend bolts)
- [x] Key scan clean before commit
