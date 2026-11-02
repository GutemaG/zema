---
id: 045-contribution-and-sync-editor-ui
unit: 002-contribution-and-sync-editor-ui
intent: 006-contribution-and-sync-editor
type: simple-construction-bolt
status: planned
stories:
  - 005-link-recording
  - 006-telegram-share
created: '2026-11-02T07:00:52Z'
started: null
completed: null
current_stage: null
stages_completed: []
requires_bolts:
  - 044-contribution-and-sync-editor-ui
enables_bolts:
  - 046-contribution-and-sync-editor-ui
requires_units: []
blocks: false
complexity:
  avg_complexity: 2
  avg_uncertainty: 3
  max_dependencies: 2
  testing_scope: 2
---

# Bolt: 045-contribution-and-sync-editor-ui

## Overview

Link recording S20 (local, YouTube) and Telegram share.

## Stories Included

- [ ] **005-link-recording**: Link recording (S20): local file and YouTube - Priority: Must
- [ ] **006-telegram-share**: Share audio from Telegram (Android) - Priority: Should

## Bolt Type

**Type**: Simple Construction Bolt
**Definition**: `.specsmd/aidlc/templates/construction/bolt-types/simple-construction-bolt.md`

## Stages

- [ ] **1. plan**: Pending → implementation-plan.md
- [ ] **2. implement**: Pending → source code + implementation-walkthrough.md
- [ ] **3. test**: Pending → tests + test-walkthrough.md

## Dependencies

### Requires
- 044-contribution-and-sync-editor-ui

### Enables
- 046-contribution-and-sync-editor-ui

## Success Criteria

- [ ] All stories implemented
- [ ] All acceptance criteria met
- [ ] Analyze and format clean (Dart); `supabase test db` passes (backend)
- [ ] Tests passing locally
- [ ] Checked on the Android emulator against the local backend
- [ ] Key scan clean before commit
