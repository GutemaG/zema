---
id: 020-cloud-lyrics-catalog-backend
unit: 001-cloud-lyrics-catalog-backend
intent: 004-cloud-lyrics-catalog
type: simple-construction-bolt
status: planned
stories:
  - 004-search-rules-to-sql
  - 005-server-search
created: 2026-10-29T05:59:04Z
started: null
completed: null
current_stage: null
stages_completed: []
requires_bolts:
  - 019-cloud-lyrics-catalog-backend
enables_bolts:
  - 021-cloud-lyrics-catalog-backend
requires_units: []
blocks: false
complexity:
  avg_complexity: 2
  avg_uncertainty: 2
  max_dependencies: 2
  testing_scope: 2
---

# Bolt: 020-cloud-lyrics-catalog-backend

## Overview

Search rules generated from zema_core into SQL, and the server search function.

## Stories Included

- [ ] **004-search-rules-to-sql**: Search rules generated into SQL - Priority: Must
- [ ] **005-server-search**: Server search function - Priority: Must

## Bolt Type

**Type**: Simple Construction Bolt
**Definition**: `.specsmd/aidlc/templates/construction/bolt-types/simple-construction-bolt.md`

## Stages

- [ ] **1. plan**: Pending → implementation-plan.md
- [ ] **2. implement**: Pending → source code + implementation-walkthrough.md
- [ ] **3. test**: Pending → tests + test-walkthrough.md

## Dependencies

### Requires
- 019-cloud-lyrics-catalog-backend

### Enables
- 021-cloud-lyrics-catalog-backend

## Success Criteria

- [ ] All stories implemented
- [ ] All acceptance criteria met
- [ ] Analyze and format clean (Dart); `supabase test db` passes (backend)
- [ ] Tests passing locally
- [ ] Checked on the Android emulator (app bolts) or against the local backend (backend bolts)

## Notes

Small bolt (intent 004 keeps bolts to 1–2 stories so each finishes in one session).
