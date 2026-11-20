---
id: 067-clip-render-share
unit: 002-clip-maker
intent: 011-share-lyrics-clips
type: simple-construction-bolt
status: in-progress
stories:
  - 003-render-clip
  - 004-share-clip
created: '2026-11-20T18:00:00Z'
started: '2026-11-20T20:30:00Z'
completed: null
current_stage: test
stages_completed: [plan, implement]
requires_bolts: [066-clip-editor]
enables_bolts: [068-clip-look]
requires_units: []
blocks: false
---

# Bolt: 067-clip-render-share

## Overview

Paint the frames with the default look, encode, then share or save; clean up.

## Built

- `clip_look.dart`: a background PNG (a two-tone gradient from the cover's main colour,
  or one of `clipGradients` picked by title; header with cover or letter tile, title,
  artist; "ዜ Zema" mark) and one transparent lyrics layer per line change: all rows
  laid out once (84 → 60 px to fit three lines), the sung row bright at 42 % of the
  height, the others dimmed; gaps and the intro show "•  •  •". After the first phone
  test (hard switches, muddy background) the lines now scroll instead of switching.
- `ClipEncoder.kt`: draws the background plus two lyric layers; on a change the old layer
  scrolls up by the new one's `scroll` while the new one slides in and fades over it
  (450 ms, eased), fading out at the edges of the lyrics band (`clipWindow`).
- `clip_controller.dart`: per-track `ClipController` (autoDispose) for the default range
  (`defaultClipRange`: from the line playing now, else 1 s before the first line, 60 s,
  kept inside the track), the preview, painting (the first 25 % of progress), the encode,
  Cancel, Share ("title – artist") and Save. Files are deleted when the screen closes.
- `ClipScreen` (`/clip?id=`): preview, range, Make video, progress with Cancel, then
  Save and Share, and the copyright note. The song menu's "Share clip" replaces the test
  item (bolt 066 adds the range editor and other entry points).
- Android `share` via a FileProvider (`${applicationId}.clips`, cache `clips/`).

## Stories Included

- [ ] **003-render-clip**
- [ ] **004-share-clip**

## Stages

- [x] **1. plan** → implementation-plan.md
- [x] **2. implement** → code + implementation-walkthrough.md
- [ ] **3. test** → tests + test-walkthrough.md
