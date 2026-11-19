---
id: 055-admin-website
unit: 002-admin-website
intent: 008-admin-website
type: simple-construction-bolt
status: complete
stories:
  - 001-admin-app-and-sign-in
created: '2026-11-19T10:00:00Z'
started: '2026-11-19T14:00:00Z'
completed: '2026-11-19T14:00:00Z'
current_stage: null
stages_completed:
  - name: plan
    completed: '2026-11-19T14:00:00Z'
    artifact: implementation-plan.md
  - name: implement
    completed: '2026-11-19T14:00:00Z'
    artifact: implementation-walkthrough.md
  - name: test
    completed: '2026-11-19T14:00:00Z'
    artifact: test-walkthrough.md
requires_bolts: [054-moderation-backend]
enables_bolts: [056-admin-website]
requires_units: []
blocks: false
---

# Bolt: 055-admin-website

## Overview

Create apps/admin, Google sign-in with the role gate, the shell, and the first Cloudflare Pages deploy.

## Stories Included

- [x] **001-admin-app-and-sign-in**: Admin app and sign-in - Must

## Stages

- [x] **1. plan** → implementation-plan.md
- [x] **2. implement** → code + implementation-walkthrough.md
- [x] **3. test** → tests + test-walkthrough.md
