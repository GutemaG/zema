---
unit: 001-lyrics-engine-and-display-ui
intent: 003-lyrics-engine-and-display
created: 2026-10-26T13:45:42Z
last_updated: 2026-10-26T20:34:59Z
---

# Construction Log: lyrics-engine-and-display-ui

## Original Plan

**From Inception**: 9 bolts planned
**Planned Date**: 2026-10-26T13:41:09Z

| Bolt ID | Stories | Type |
|---------|---------|------|
| 009-lyrics-engine-and-display-ui | 001, 002 | simple-construction-bolt |
| 010-lyrics-engine-and-display-ui | 003, 004 | simple-construction-bolt |
| 011-lyrics-engine-and-display-ui | 005, 006 | simple-construction-bolt |
| 012-lyrics-engine-and-display-ui | 007, 008 | simple-construction-bolt |
| 013-lyrics-engine-and-display-ui | 009, 010 | simple-construction-bolt |
| 014-lyrics-engine-and-display-ui | 011 | simple-construction-bolt |
| 015-lyrics-engine-and-display-ui | 012, 013 | simple-construction-bolt |
| 016-lyrics-engine-and-display-ui | 014, 015 | simple-construction-bolt |
| 017-lyrics-engine-and-display-ui | 016 | simple-construction-bolt |

## Replanning History

| Date | Action | Change | Reason | Approved |
|------|--------|--------|--------|----------|

## Current Bolt Structure

| Bolt ID | Stories | Status | Changed |
|---------|---------|--------|---------|
| 009-lyrics-engine-and-display-ui | 001, 002 | ✅ completed | - |
| 010-lyrics-engine-and-display-ui | 003, 004 | ✅ completed | - |
| 011-lyrics-engine-and-display-ui | 005, 006 | ✅ completed | - |
| 012-lyrics-engine-and-display-ui | 007, 008 | ✅ completed | - |
| 013-lyrics-engine-and-display-ui | 009, 010 | ✅ completed | - |
| 014-lyrics-engine-and-display-ui | 011 | ✅ completed | - |
| 015-lyrics-engine-and-display-ui | 012, 013 | ✅ completed | - |
| 016-lyrics-engine-and-display-ui | 014, 015 | ✅ completed | - |
| 017-lyrics-engine-and-display-ui | 016 | [ ] planned | - |

## Execution History

| Date | Bolt | Event | Details |
|------|------|-------|---------|
| 2026-10-26T13:45:42Z | 009-lyrics-engine-and-display-ui | started | Stage 1: plan |
| 2026-10-26T13:47:57Z | 009-lyrics-engine-and-display-ui | stage-complete | plan → implement |
| 2026-10-26T13:53:06Z | 009-lyrics-engine-and-display-ui | stage-complete | implement → test |
| 2026-10-26T14:28:23Z | 009-lyrics-engine-and-display-ui | completed | All 3 stages done; 620 tests pass |
| 2026-10-26T14:28:52Z | 010-lyrics-engine-and-display-ui | started | Stage 1: plan |
| 2026-10-26T14:50:03Z | 010-lyrics-engine-and-display-ui | stage-complete | plan → implement |
| 2026-10-26T14:51:32Z | 010-lyrics-engine-and-display-ui | stage-complete | implement → test |
| 2026-10-26T14:59:37Z | 010-lyrics-engine-and-display-ui | completed | All 3 stages done; 654 tests pass |
| 2026-10-26T14:59:54Z | 011-lyrics-engine-and-display-ui | started | Stage 1: plan |
| 2026-10-26T15:17:00Z | 011-lyrics-engine-and-display-ui | stage-complete | plan → implement |
| 2026-10-26T15:22:20Z | 011-lyrics-engine-and-display-ui | stage-complete | implement → test |
| 2026-10-26T17:26:56Z | 011-lyrics-engine-and-display-ui | completed | All 3 stages done; 683 tests pass |
| 2026-10-26T17:27:14Z | 012-lyrics-engine-and-display-ui | started | Stage 1: plan |
| 2026-10-26T17:29:32Z | 012-lyrics-engine-and-display-ui | stage-complete | plan → implement |
| 2026-10-26T17:30:44Z | 012-lyrics-engine-and-display-ui | stage-complete | implement → test |
| 2026-10-26T17:35:18Z | 012-lyrics-engine-and-display-ui | completed | All 3 stages done; 722 tests pass |
| 2026-10-26T17:35:47Z | 013-lyrics-engine-and-display-ui | started | Stage 1: plan |
| 2026-10-26T17:36:45Z | 013-lyrics-engine-and-display-ui | stage-complete | plan → implement |
| 2026-10-26T17:39:38Z | 013-lyrics-engine-and-display-ui | stage-complete | implement → test |
| 2026-10-26T17:43:37Z | 013-lyrics-engine-and-display-ui | completed | All 3 stages done; 753 tests pass |
| 2026-10-26T17:43:44Z | 014-lyrics-engine-and-display-ui | started | Stage 1: plan |
| 2026-10-26T17:44:38Z | 014-lyrics-engine-and-display-ui | stage-complete | plan → implement |
| 2026-10-26T17:49:24Z | 014-lyrics-engine-and-display-ui | stage-complete | implement → test |
| 2026-10-26T19:31:20Z | 014-lyrics-engine-and-display-ui | completed | All 3 stages done; 778 tests pass |
| 2026-10-26T19:32:18Z | 015-lyrics-engine-and-display-ui | started | Stage 1: plan |
| 2026-10-26T19:50:28Z | 015-lyrics-engine-and-display-ui | stage-complete | plan → implement |
| 2026-10-26T19:50:28Z | 015-lyrics-engine-and-display-ui | stage-complete | implement → test |
| 2026-10-26T19:58:12Z | 015-lyrics-engine-and-display-ui | completed | All 3 stages done; 800 tests pass |
| 2026-10-26T19:59:00Z | 016-lyrics-engine-and-display-ui | started | Stage 1: plan |
| 2026-10-26T20:03:16Z | 016-lyrics-engine-and-display-ui | stage-complete | plan → implement |
| 2026-10-26T20:03:16Z | 016-lyrics-engine-and-display-ui | stage-complete | implement → test |
| 2026-10-26T20:34:59Z | 016-lyrics-engine-and-display-ui | completed | All 3 stages done; 818 tests pass |

## Notes

- **Bolt 009**: Home replaces "Coming soon". A test found a crash when Home asked an off-screen Library for a tab (fixed by switching after the next frame). The permission states are now shared through `LibraryAccessGate`.
- **Bolt 010**: search normalization and transliteration in `zema_core` (rules as data tables). Known limit: words with the same consonants match (amlak / malak).
- **Bolt 011**: Search tab over the library with chips and recent searches; album and artist pages also under `/search` so Back returns to the results.
- **Bolt 012**: lyrics models with checked JSON, play-order expansion and a stateless sync engine in `zema_core`. Offset: positive shows lines later.
- **Bolt 013**: LRC import with chorus detection, `LyricsRepository`, three placeholder songs (need native review), `test_audio.sh --lyrics`.
- Bolt 014: app tests read bundled lyrics from disk (`DiskAssetBundle`); real asset loading stalls under the widget-test clock.
- Bolt 015: auto-scroll asks for a frame (`scheduleFrame`); while paused none comes otherwise.
- Bolt 016: Song detail is registered under Library and Search only; View lyrics uses `detailBase`.
