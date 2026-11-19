---
id: 054-moderation-backend
unit: 001-moderation-backend
intent: 008-admin-website
type: simple-construction-bolt
status: complete
stories:
  - 001-reports-for-moderators
  - 002-hide-and-restore-songs
created: '2026-11-19T10:00:00Z'
started: '2026-11-19T12:00:00Z'
completed: '2026-11-19T12:00:00Z'
current_stage: null
stages_completed:
  - name: plan
    completed: '2026-11-19T12:00:00Z'
    artifact: implementation-plan.md
  - name: implement
    completed: '2026-11-19T12:00:00Z'
    artifact: implementation-walkthrough.md
  - name: test
    completed: '2026-11-19T12:00:00Z'
    artifact: test-walkthrough.md
requires_bolts: []
enables_bolts: [055-admin-website]
requires_units: []
blocks: false
---

# Bolt: 054-moderation-backend

## Overview

New moderator RPCs for reports and hiding songs; migration applied to hosted only after the owner confirms.

## Stories Included

- [x] **001-reports-for-moderators**: Reports for moderators - Must
- [x] **002-hide-and-restore-songs**: Hide and restore songs - Must

## Stages

- [x] **1. plan** → implementation-plan.md
- [x] **2. implement** → code + implementation-walkthrough.md
- [x] **3. test** → tests + test-walkthrough.md
