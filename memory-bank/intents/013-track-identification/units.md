---
intent: 013-track-identification
phase: inception
status: units-decomposed
updated: 2026-11-19T16:00:00Z
---

# Identify Badly Tagged Tracks - Unit Decomposition

### Unit 1: 001-track-print-core
`zema_core`: tag clean-up for `SongMatcher`, and the track print with its eval.
**Stories**: 001-clean-tags, 002-track-print

### Unit 2: 002-track-print-backend
Table, `match_track`, `share_track_print` with the two-install rule, review RPCs. pgTAP.
**Stories**: 003-store-and-match, 004-share-prints

### Unit 3: 003-track-print-app
Mobile: print on play and scan, look up, link, share after a link.
**Stories**: 005-identify-by-print, 006-share-after-link

### Unit 4: 004-track-print-review
Admin site: pending track prints on the Fingerprints page.
**Stories**: 007-review-track-prints

## Bolts

| Bolt | Unit | Stories |
|------|------|---------|
| 058-track-print-core | 1 | 001 |
| 059-track-print-core | 1 | 002 (eval gate) |
| 060-track-print-backend | 2 | 003, 004 |
| 061-track-print-app | 3 | 005, 006 |
| 062-track-print-review | 4 | 007 |
