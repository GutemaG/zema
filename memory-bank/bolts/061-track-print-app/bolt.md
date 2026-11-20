---
id: 061-track-print-app
unit: 003-track-print-app
intent: 013-track-identification
type: simple-construction-bolt
status: complete
stories:
  - 005-identify-by-print 006-share-after-link
created: '2026-11-19T16:00:00Z'
started: '2026-11-20T08:00:00Z'
completed: '2026-11-20T10:00:00Z'
current_stage: null
stages_completed: [plan, implement, test]
requires_bolts: []
enables_bolts: [062-track-print-review]
requires_units: []
blocks: false
---

# Bolt: 061-track-print-app

## Overview

Print, look up, link and share on the phone.

## Stories Included

- [x] **005-identify-by-print 006-share-after-link**

## Stages

- [x] **1. plan** → implementation-plan.md
- [x] **2. implement** → code + implementation-walkthrough.md
- [x] **3. test** → tests + test-walkthrough.md

## Result

- `SoundLinker` prints from the same decode (now 110 s). The print is looked up when sound finds nothing, in the background as well as on play, and lookups pause for 30 minutes after a network or limit failure.
- The phone's `track_prints` table is new in Drift v17.
- Link order is manual → sound → title → print (`trackPrintMatchProvider`).
- `TrackPrintSharer` sends one file per song linked by title or by hand, once, with consent. The Share switch and the ask dialog are back; they cover prints even with `ZEMA_FINGERPRINT_UPLOADS` off.
- Dropped: a separate contribution path. An approved contribution's file is linked to its song, so the sharer sends its print.
- Tests: linker (6 new), sharer (6), repository (3), and a live local backend test (two installs publish, then a copy matches).
