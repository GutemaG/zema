---
id: 065-clip-encoder
unit: 001-clip-encoder
intent: 011-share-lyrics-clips
type: simple-construction-bolt
status: planned
stories:
  - 001-encode-clip
created: '2026-11-20T18:00:00Z'
started: null
completed: null
current_stage: null
stages_completed: []
requires_bolts: []
enables_bolts: [066-clip-editor]
requires_units: []
blocks: false
---

# Bolt: 065-clip-encoder

## Overview

Native Android encoder (`ClipEncoder.kt`, channel `zema/clip`) behind a Dart `ClipEncoder`. Timing gate: the owner times a 60 s clip on their phone through a debug action; under 30 s, or fall back to 720×1280.

## Stories Included

- [ ] **001-encode-clip**

## Stages

- [ ] **1. plan** → implementation-plan.md
- [ ] **2. implement** → code + implementation-walkthrough.md
- [ ] **3. test** → tests + test-walkthrough.md
