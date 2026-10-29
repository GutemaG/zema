---
id: 029-accounts-backend
unit: 001-accounts-backend
intent: 005-accounts-backup-restore
type: simple-construction-bolt
status: planned
stories:
  - 001-profiles-and-roles
  - 002-google-auth-config
created: '2026-10-29T19:05:45Z'
started: null
completed: null
current_stage: null
stages_completed: []
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

- [ ] **001-profiles-and-roles**: Profiles made on sign-up, with roles - Priority: Must
- [ ] **002-google-auth-config**: Google provider config and setup guide - Priority: Must

## Bolt Type

**Type**: Simple Construction Bolt
**Definition**: `.specsmd/aidlc/templates/construction/bolt-types/simple-construction-bolt.md`

## Stages

- [ ] **1. plan**: Pending → implementation-plan.md
- [ ] **2. implement**: Pending → source code + implementation-walkthrough.md
- [ ] **3. test**: Pending → tests + test-walkthrough.md

## Dependencies

### Requires
- Intent 004 (complete)

### Enables
- 030-accounts-backend

## Success Criteria

- [ ] All stories implemented
- [ ] All acceptance criteria met
- [ ] Analyze and format clean (Dart); `supabase test db` passes (backend)
- [ ] Tests passing locally
- [ ] Checked on the Android emulator (app bolts) or against the local backend (backend bolts)
- [ ] Key scan clean before commit
