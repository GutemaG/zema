---
id: 065-clip-encoder
unit: 001-clip-encoder
intent: 011-share-lyrics-clips
type: simple-construction-bolt
status: complete
stories:
  - 001-encode-clip
created: '2026-11-20T18:00:00Z'
started: '2026-11-20T18:30:00Z'
completed: '2026-11-20T20:00:00Z'
current_stage: null
stages_completed: [plan, implement, test]
requires_bolts: []
enables_bolts: [066-clip-editor]
requires_units: []
blocks: false
---

# Bolt: 065-clip-encoder

## Overview

Native Android encoder (`ClipEncoder.kt`, channel `zema/clip`) behind a Dart `ClipEncoder`. Timing gate: the owner times a 60 s clip on their phone through a debug action; under 30 s, or fall back to 720×1280.

## Stories Included

- [x] **001-encode-clip**

## Built

- `ClipEncoder.kt`: decodes the clip's part of the file (16-bit, at most stereo, 50 ms fade
  in, 500 ms out) and encodes AAC 128 kb/s in memory; then draws each picture with EGL
  onto the H.264 encoder's surface at 30 fps with exact presentation times (6 Mb/s at
  1080×1920; 720×1280 at 3.5 Mb/s where 1080 isn't supported) and muxes both. No audio
  gives a silent track (for bolt 069). Cancel deletes the file. Each picture
  cross-fades into the next over 250 ms centred on its time (two textures blended in GL;
  added after the phone test showed hard cuts).
- `ClipChannel.kt` (`zema/clip`): `encode`, `cancel`, `saveToGallery` (Movies/Zema,
  Android 10+), `progress` calls to Dart. One encode at a time.
- Dart `ClipEncoder` (`features/clips/data`), `ClipRequest` checks (≤ 2 min, frames in
  order from zero), `clipFrameTimes` (one frame per line change).
- Temporary song menu item "Test clip video (60 s)": 60 s from the first line with plain
  frames, saved to the gallery, shows the render time and size. Replaced by Share clip
  in bolt 066.
- APK 78.2 MB (+0.1 MB).

## Tests

`test/features/clips/clip_encoder_test.dart` (9): frame times, request checks, the
channel's arguments, progress, cancel and failures. Analyze clean, 1,473 pass.

## Timing gate (passed)

Owner's phone: 60 s in 14.5 s, audio clean, lines in time; Ethiopic renders. Hard cuts
between lines led to the cross-fade. The plain test frames look bad, as expected: the
look is bolt 067's.

## Stages

- [x] **1. plan** → implementation-plan.md
- [x] **2. implement** → code + implementation-walkthrough.md
- [x] **3. test** → tests + test-walkthrough.md
