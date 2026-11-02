---
id: 040-contribution-backend
unit: 001-contribution-backend
intent: 006-contribution-and-sync-editor
type: simple-construction-bolt
status: planned
stories:
  - 002-review-and-moderator-role
created: '2026-11-02T07:00:52Z'
started: null
completed: null
current_stage: null
stages_completed: []
requires_bolts:
  - 039-contribution-backend
enables_bolts:
  - 041-contribution-backend
requires_units: []
blocks: false
complexity:
  avg_complexity: 2
  avg_uncertainty: 1
  max_dependencies: 1
  testing_scope: 2
---

# Bolt: 040-contribution-backend

## Overview

Review RPC, moderator queue read and the moderator script.

## Stories Included

- [ ] **002-review-and-moderator-role**: Review RPC and the moderator role - Priority: Must

## Bolt Type

**Type**: Simple Construction Bolt
**Definition**: `.specsmd/aidlc/templates/construction/bolt-types/simple-construction-bolt.md`

## Stages

- [ ] **1. plan**: Pending → implementation-plan.md
- [ ] **2. implement**: Pending → source code + implementation-walkthrough.md
- [ ] **3. test**: Pending → tests + test-walkthrough.md

## Dependencies

### Requires
- 039-contribution-backend

### Enables
- 041-contribution-backend

## Success Criteria

- [ ] All stories implemented
- [ ] All acceptance criteria met
- [ ] Analyze and format clean (Dart); `supabase test db` passes (backend)
- [ ] Tests passing locally
- [ ] Checked against the local backend
- [ ] Key scan clean before commit
