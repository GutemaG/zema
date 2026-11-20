---
id: 066-clip-editor
unit: 002-clip-maker
intent: 011-share-lyrics-clips
type: simple-construction-bolt
status: in-progress
stories:
  - 002-pick-clip
created: '2026-11-20T18:00:00Z'
started: '2026-11-20T23:00:00Z'
completed: null
current_stage: test
stages_completed: [plan, implement]
requires_bolts: [065-clip-encoder]
enables_bolts: [067-clip-render-share]
requires_units: []
blocks: false
---

# Bolt: 066-clip-editor

## Overview

The clip editor with handles, snapping, preview and its three entry points.

## Built

- On `ClipScreen`: a range slider over the track whose moved handle snaps to a line start
  within 2 s (`snapToLine`); the other gives way to keep 5 s to 2 min inside the track
  (`clampClipRange`). Buttons move the start or end a line earlier or later
  (`stepToLine`) for screen readers.
- Play on the preview plays just the selection (`ClippingAudioSource` in its own player,
  pausing the main one), and the preview follows the lines.
- Entry points: the song menu everywhere, including Now Playing. Song detail is for
  catalogue songs, not library tracks, so it has none.

## Stories Included

- [ ] **002-pick-clip**

## Stages

- [ ] **1. plan** → implementation-plan.md
- [ ] **2. implement** → code + implementation-walkthrough.md
- [ ] **3. test** → tests + test-walkthrough.md
