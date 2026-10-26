---
unit: 001-lyrics-engine-and-display-ui
intent: 003-lyrics-engine-and-display
unit_type: frontend
default_bolt_type: simple-construction-bolt
phase: inception
status: stories-defined
created: 2026-10-26T13:41:09Z
updated: 2026-10-26T13:41:09Z
---

# Unit Brief: Lyrics Engine and Display UI

## Purpose

Replace the Home and Search "Coming soon" tabs, then show synced lyrics for local songs
from bundled sample data. The pure lyrics and search logic goes into `zema_core` so the
cloud catalog (004), sync editor (006) and floating lyrics (007) reuse it.

## Scope

### In Scope
- Home (S05): header, quick actions, continue listening, recently played, your playlists
- Ethiopic normalization and transliteration matching as data tables (`zema_core`)
- Search (S06) over the library and lyric text, scope chips, recent searches
- Lyrics models, play order, sync engine, LRC import (`zema_core`)
- `LyricsRepository` with bundled placeholder songs and a test-audio script
- Track-to-song links (automatic + manual) in Drift schema v2
- Lyrics view (C06) on Now Playing (S08), Song detail (S07), Lyrics settings (S28)

### Out of Scope
- Network, cloud catalog (004), accounts (005), contributions and Contribute tab (006)
- Now-detected card and floating lyrics (007); community lyrics row on Home
- Album-art background colors on S08; Recordings tab; report wrong lyrics
- Translating new strings into am/om/ti (English fallback)

---

## Assigned Requirements

| FR | Requirement | Priority |
|----|-------------|----------|
| FR-1 | Home (S05) | Must |
| FR-2 | Ethiopic normalization | Must |
| FR-3 | Transliteration matching | Must |
| FR-4 | Search (S06) | Must |
| FR-5 | Lyrics domain models | Must |
| FR-6 | Play-order expansion | Must |
| FR-7 | Sync engine | Must |
| FR-8 | LRC import | Must |
| FR-9 | `LyricsRepository` + bundled sample data | Must |
| FR-10 | Link local tracks to songs | Must |
| FR-11 | Lyrics view (C06) on S08 | Must |
| FR-12 | Song detail (S07) | Must |
| FR-13 | Lyrics settings (S28) | Must |

---

## Domain Concepts

### Key Entities
| Entity | Description | Attributes |
|--------|-------------|------------|
| `Song` | Canonical lyrics | id, title, transliteration, artist, album, sections, playOrder |
| `LyricSection` | Verse / chorus / bridge | id, kind, lines (text, transliteration) |
| `PlayOrder` | Sung order of sections | list of section IDs |
| `LineOccurrence` | One sung line in play order | index, sectionId, lineIndex, repeat |
| `Recording` | One performance | id, songId, artist, source, duration, offset |
| `SyncTiming` | Start time per occurrence | recordingId, starts |
| `TrackSongLink` | Local track ↔ song | trackId, songId, recordingId, source (auto/manual) |

### Key Operations
| Operation | Description | Inputs | Outputs |
|-----------|-------------|--------|---------|
| `normalize` | Fold variants, drop noise | text | normalized text |
| `skeleton` / `transliterationScore` | Latin ↔ Ethiopic match | query, target | score |
| `expandPlayOrder` | Flatten sections | song | occurrences |
| `SyncEngine.lineAt` | Current and next line | position, offset, timing | indexes |
| `importLrc` | LRC → models | LRC text | song, recording, timing, errors |

---

## Story Summary

| Metric | Count |
|--------|-------|
| Total Stories | 16 |
| Must Have | 16 |
| Should Have | 0 |
| Could Have | 0 |

### Stories

| Story ID | Title | Priority | Status |
|----------|-------|----------|--------|
| 001-home-header-and-quick-actions | Home header and quick actions | Must | Complete |
| 002-home-continue-and-recent-rows | Home continue listening and recent rows | Must | Complete |
| 003-ethiopic-normalization | Ethiopic search normalization | Must | Planned |
| 004-transliteration-matching | Transliteration matching | Must | Planned |
| 005-search-screen | Search screen | Must | Planned |
| 006-recent-searches | Recent searches | Must | Planned |
| 007-lyrics-models-and-play-order | Lyrics models and play order | Must | Planned |
| 008-sync-engine | Sync engine | Must | Planned |
| 009-lrc-import | LRC import | Must | Planned |
| 010-bundled-lyrics-repository | Bundled lyrics repository and sample songs | Must | Planned |
| 011-track-song-linking | Link local tracks to songs | Must | Planned |
| 012-lyrics-view-now-playing | Lyrics view on Now Playing | Must | Planned |
| 013-lyrics-scroll-and-offset | Lyrics auto-scroll and sync offset | Must | Planned |
| 014-song-detail | Song detail | Must | Planned |
| 015-lyric-text-search | Lyric text search | Must | Planned |
| 016-lyrics-settings | Lyrics settings | Must | Planned |

---

## Dependencies

### Depends On
| Unit | Reason |
|------|--------|
| 001-app-foundation-ui (intent 001) | Shell, theme, l10n, C07, settings |
| 001-local-library-and-player-ui (intent 002) | Tracks, player position, history, playlists, song menu, Drift |

### Depended By
| Unit | Reason |
|------|--------|
| Intent 004 cloud catalog | Models, normalization tables |
| Intent 006 contribution | Models, LRC, C06 |
| Intent 007 floating lyrics | C06, sync engine |

---

## Technical Context

### Suggested Technology
Existing stack (Riverpod, drift, go_router). No new packages expected; `unorm_dart` or
built-in NFC only if needed. Test audio from `ffmpeg` as in intent 002.

### Data Storage
| Data | Type | Volume | Retention |
|------|------|--------|-----------|
| Sample lyrics | App assets | 3–5 songs | Shipped with the app |
| Track-to-song links | Drift (schema v2) | ≤ library size | Until app data cleared |
| Lyrics settings, offsets, recent searches | shared_preferences | ~10 keys + offsets | Until app data cleared |

---

## Constraints

- Search and lyrics logic is pure Dart in `zema_core`, no Flutter imports.
- Normalization rules as data tables; never strip Ethiopic characters.
- No `Color(0x…)` literals outside `lib/app/theme/`; no user-visible string literals.
- iOS build must keep compiling.

---

## Success Criteria

### Functional
- [ ] Home and Search show real content; no "Coming soon" on those tabs (Home done in bolt 009)
- [ ] "kidist", "ቅድስት", "ቅዱስት" find the same song
- [ ] A sample song plays on the emulator with lines highlighted within ±0.3 s
