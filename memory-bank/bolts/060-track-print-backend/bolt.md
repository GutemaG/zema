---
id: 060-track-print-backend
unit: 002-track-print-backend
intent: 013-track-identification
type: simple-construction-bolt
status: complete
stories:
  - 003-store-and-match 004-share-prints
created: '2026-11-19T16:00:00Z'
started: '2026-11-19T21:30:00Z'
completed: '2026-11-19T22:30:00Z'
current_stage: null
stages_completed: [plan, implement, test]
requires_bolts: []
enables_bolts: [061-track-print-app]
requires_units: []
blocks: false
---

# Bolt: 060-track-print-backend

## Overview

Track print table, match and share RPCs; hosted migration after the owner confirms.

## Stories Included

- [x] **003-store-and-match 004-share-prints**

## Stages

- [x] **1. plan** → implementation-plan.md
- [x] **2. implement** → code + implementation-walkthrough.md
- [x] **3. test** → tests + test-walkthrough.md

## Carried over

- From 058: the length tie-break (story 001). **Dropped:** same-title songs are told apart by their prints now, and lengths in the song index would need a client change too.

## Result

- Migration `20261119010000_track_prints.sql`; pgTAP `020_track_prints.test.sql` (40 tests); all 680 pass.
- Fixed in `016`: the IP test counted every `identify_counts` row, and local data had leftover rows. It now counts only `ip:` keys.
- 10,000 prints locally: `match_track` 50–66 ms for a copy, 13 ms for no match.
  Storage is 101 MB of prints and 132 MB of keys. That misses the 100 MB target; the knob is the key stride.
- Seed tool `tool/upload_track_prints.dart`, tried on a real file and its 64 kbps copy (`not_needed`).
- Applied to local and to production (2026-11-19). `match_track` answers there.
- A matching second share publishes one print and drops the other, not both: they are the same recording.
