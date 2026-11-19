---
id: 059-track-print-core
unit: 001-track-print-core
intent: 013-track-identification
type: simple-construction-bolt
status: complete
stories:
  - 002-track-print
created: '2026-11-19T16:00:00Z'
started: '2026-11-19T19:30:00Z'
completed: '2026-11-19T21:00:00Z'
current_stage: null
stages_completed: [plan, implement, test]
requires_bolts: []
enables_bolts: [060-track-print-backend]
requires_units: []
blocks: false
---

# Bolt: 059-track-print-core

## Overview

Track print, comparison and the eval; stop if the eval fails.

## Stories Included

- [x] **002-track-print**

## Stages

- [x] **1. plan** → implementation-plan.md
- [x] **2. implement** → code + implementation-walkthrough.md
- [x] **3. test** → tests + test-walkthrough.md

## Result: gate passed

The eval (`tool/track_print_eval.dart`) ran on the owner's 98 files, compiled:

| | hop 512 | **hop 256 (chosen)** |
|---|---|---|
| Worst copy | 26.7 % | 17.5 % (AAC 128) |
| Closest different file | 48.6 % | 48.6 % |
| Fewest shared keys, stride 8 | 3 | 31 |
| Size, time per print | 5.0 KB, 115 ms | 9.2 KB (110 s), 114 ms |

Settings:

- **Threshold:** `trackPrintMatch` = 30 %.
- **Length:** cut from 120 s to 110 s, to stay ≤ 10 KB.
- **Keys:** at stride 4, a copy shares ≥ 63 keys, against a mean of 8 and a maximum of
  46 for different files. Rank candidates by shared keys, then compare them.

Not covered: different masters of one song and different intros; none were in the set.
