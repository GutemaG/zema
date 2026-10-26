---
intent: 003-lyrics-engine-and-display
phase: inception
status: units-decomposed
updated: 2026-10-26T13:41:09Z
---

# Lyrics Engine and Display - Unit Decomposition

## Units Overview

Project type `frontend-app` → one feature-based frontend unit (`{intent}-ui`,
simple-construction-bolt). Pure-Dart logic goes into `packages/zema_core` as part of
the same unit. This intent decomposes into **1 unit**:

### Unit 1: 001-lyrics-engine-and-display-ui

**Description**: Home and Search tabs, Ethiopic normalization and transliteration, the
lyrics model, play order, sync engine and LRC import in `zema_core`, bundled sample
lyrics, track-to-song linking, the lyrics view (C06) on Now Playing, Song detail (S07)
and the Lyrics section in Settings.

**Stories**:

- 001-home-header-and-quick-actions
- 002-home-continue-and-recent-rows
- 003-ethiopic-normalization
- 004-transliteration-matching
- 005-search-screen
- 006-recent-searches
- 007-lyrics-models-and-play-order
- 008-sync-engine
- 009-lrc-import
- 010-bundled-lyrics-repository
- 011-track-song-linking
- 012-lyrics-view-now-playing
- 013-lyrics-scroll-and-offset
- 014-song-detail
- 015-lyric-text-search
- 016-lyrics-settings

**Deliverables**:

- `apps/mobile/lib/features/home/`, `features/search/`, `features/lyrics/`
- `packages/zema_core/lib/src/search/` (normalization, transliteration tables)
- `packages/zema_core/lib/src/lyrics/` (models, play order, sync engine, LRC import, repository interface)
- `apps/mobile/assets/lyrics/` (sample songs) and a script to generate matching test audio
- Drift schema v2 (track-to-song links) with migration test
- ARB strings in en (am/om/ti fall back to English)
- Unit, Drift and widget tests; emulator checks

**Dependencies**:

- Depends on: `001-app-foundation-ui`, `001-local-library-and-player-ui` (intents 001–002)
- Depended by: intents 004 (cloud catalog reuses models and normalization), 006 (sync editor), 007 (floating lyrics reuse C06)

**Estimated Complexity**: L

## Requirement-to-Unit Mapping

- **FR-1** Home → stories 001, 002
- **FR-2** Ethiopic normalization → 003
- **FR-3** Transliteration matching → 004
- **FR-4** Search → 005, 006, 015
- **FR-5** Lyrics models / **FR-6** Play order → 007
- **FR-7** Sync engine → 008
- **FR-8** LRC import → 009
- **FR-9** Repository + sample data → 010
- **FR-10** Track-to-song linking → 011
- **FR-11** Lyrics view (C06) on S08 → 012, 013
- **FR-12** Song detail (S07) → 014
- **FR-13** Lyrics settings → 016

## Unit Dependency Graph

```text
[001-local-library-and-player-ui] (intent 002, complete)
            │
            ▼
[001-lyrics-engine-and-display-ui]
```

## Execution Order

Small bolts (1–2 stories) so each finishes in one session:

1. Bolt 009: Home (001–002)
2. Bolt 010: normalization + transliteration (003–004)
3. Bolt 011: Search screen (005–006)
4. Bolt 012: lyrics models, play order, sync engine (007–008)
5. Bolt 013: LRC import + bundled sample lyrics (009–010)
6. Bolt 014: track-to-song linking (011)
7. Bolt 015: lyrics view on Now Playing (012–013)
8. Bolt 016: Song detail + lyric text search (014–015)
9. Bolt 017: lyrics settings + intent checks (016)
