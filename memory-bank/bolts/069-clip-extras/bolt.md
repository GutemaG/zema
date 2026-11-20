---
id: 069-clip-extras
unit: 002-clip-maker
intent: 011-share-lyrics-clips
type: simple-construction-bolt
status: complete
stories:
  - 005-text-only-clip
  - 006-lyrics-only-clip
created: '2026-11-20T18:00:00Z'
started: '2026-11-21T01:10:00Z'
completed: '2026-11-21T01:40:00Z'
current_stage: null
stages_completed: [plan, implement, test]
requires_bolts: [068-clip-look]
enables_bolts: []
requires_units: []
blocks: false
---

# Bolt: 069-clip-extras

## Overview

Static page for lyrics without timing, and the video without the song.

## Built

- Lyrics without timing: the Clip tab lists the lines as checkboxes. The first 4
  non-empty lines are ticked by default, up to 8 (`ClipController.maxPicked`). They show
  as one still page (`ClipLyricsLayout.page`): every row bright, the block centred on the
  text position, one frame for the whole clip. With none ticked, the page shows "•  •  •".
- Without the song: a switch in the Clip tab sends no audio, so the encoder writes silence.
  The lyric timing and the chosen look stay the same.
- Emulator run: the test song was linked to the text-only "Sikuar". Unticking and
  re-ticking the line updated the preview. The 40 s silent clip has the page throughout
  (loudest point −91 dB).

## Stories Included

- [x] **005-text-only-clip**
- [x] **006-lyrics-only-clip**

## Stages

- [x] **1. plan** → implementation-plan.md
- [x] **2. implement** → code + implementation-walkthrough.md
- [x] **3. test** → tests + test-walkthrough.md

## Tests

`clip_look_test` checks that the still page is centred on the text position. 1,487 tests pass.
