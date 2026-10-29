---
id: 023-cloud-lyrics-catalog-ui
unit: 002-cloud-lyrics-catalog-ui
intent: 004-cloud-lyrics-catalog
type: simple-construction-bolt
status: complete
stories:
  - 002-song-index
created: '2026-10-29T05:59:04Z'
started: '2026-10-29T08:49:53Z'
completed: 2026-10-29T09:42:06Z
current_stage: null
stages_completed: []
requires_bolts:
  - 022-cloud-lyrics-catalog-ui
enables_bolts:
  - 024-cloud-lyrics-catalog-ui
requires_units: []
blocks: false
complexity:
  avg_complexity: 2
  avg_uncertainty: 1
  max_dependencies: 2
  testing_scope: 2
---

# Bolt: 023-cloud-lyrics-catalog-ui

## Overview

Song index in Drift (schema v3) with refresh and offline use.

## Stories Included

- [x] **002-song-index**: Song index on the phone - Priority: Must

## Bolt Type

**Type**: Simple Construction Bolt
**Definition**: `.specsmd/aidlc/templates/construction/bolt-types/simple-construction-bolt.md`

## Stages

- [x] **1. plan**: Pending → implementation-plan.md
- [x] **2. implement**: Pending → source code + implementation-walkthrough.md
- [x] **3. test**: Complete → tests + test-walkthrough.md

## Dependencies

### Requires
- 022-cloud-lyrics-catalog-ui

### Enables
- 024-cloud-lyrics-catalog-ui

## Success Criteria

- [x] All stories implemented
- [x] All acceptance criteria met
- [x] Analyze and format clean (Dart); `supabase test db` passes (backend)
- [x] Tests passing locally
- [x] Checked on the Android emulator (app bolts) or against the local backend (backend bolts)

## Notes

Small bolt (intent 004 keeps bolts to 1–2 stories so each finishes in one session).
