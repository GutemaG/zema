---
intent: 003-lyrics-engine-and-display
phase: inception
status: draft
created: 2026-10-23T22:16:40Z
updated: 2026-10-23T22:16:40Z
---

# Requirements: Lyrics Engine and Display

> Source: `docs/roadmap.md` Stage 3 · screens: `docs/screens.md` S05, S06, S07, S08, S28,
> C06 · domain model: `docs/flutter-build-notes.md` · Complexity ★★★☆☆ · No network
> (bundled sample data).

## Intent Overview

Show synced lyrics for local songs using bundled sample data, proving the lyrics model,
sync engine, and Ethiopic search before any backend exists.

## Business Goals

| Goal | Success Metric | Priority |
|------|----------------|----------|
| Accurate synced lyrics | Lines highlighted within ±0.3 s of timing data | Must |
| Search works with any keyboard | "kidist", "ቅድስት", "ቅዱስት" find the same song | Must |
| Proven core logic | Unit tests cover sync engine, play order, normalization | Must |

---

## Functional Requirements

### FR-1: Lyrics domain models (`zema_core`)
- **Description**: Song, LyricSection (verse/chorus/bridge + lines), PlayOrder, Recording, SyncTiming as immutable pure-Dart models.
- **Priority**: Must

### FR-2: Play-order expansion
- **Description**: Expand PlayOrder into a flat sequence of line occurrences (chorus written once, repeated); each occurrence addressable for timing.
- **Acceptance Criteria**: Unit tests for repeated chorus, bridge, empty sections.
- **Priority**: Must

### FR-3: Sync engine
- **Description**: Given position + per-recording offset → current line occurrence index (and next line); handles seek and pre-first-line.
- **Acceptance Criteria**: Correct within ±0.3 s; unit-tested including boundaries.
- **Priority**: Must

### FR-4: Ethiopic search normalization
- **Description**: Fold ሀ/ሐ/ኀ, ሰ/ሠ, አ/ዐ, ጸ/ፀ (…), transliteration ↔ Ethiopic, case/punctuation, strip noise ("Official Video", "New Mezmur", years). Unicode-safe — never strip Ethiopic characters.
- **Priority**: Must

### FR-5: `LyricsRepository` interface + `FakeLyricsRepository`
- **Description**: Interface in `zema_core`; fake loads bundled JSON of sample songs.
- **Priority**: Must

### FR-6: Link local tracks to songs
- **Description**: Automatic match by normalized title + artist; manual "Match" action; matches saved locally (Drift).
- **Priority**: Must

### FR-7: Lyrics view (C06) in Now Playing (S08)
- **Description**: Current line highlighted (`primaryText`) and auto-scrolled; past lines dimmed (`faint`); tap line to seek; chorus markers; transliteration toggle; font size; per-recording sync offset ±0.5 s; auto-scroll pauses on manual scroll and resumes after a few seconds; plain-text fallback.
- **Priority**: Must

### FR-8: Song detail (S07) — Lyrics and Info tabs
- **Priority**: Must

### FR-9: Search (S06)
- **Description**: Across local library and sample lyrics — songs, artists, albums, lyric text; scope chips; recent searches; grouped results.
- **Priority**: Must

### FR-10: Home (S05)
- **Description**: Quick actions, continue listening, recently played, your playlists, header with search and profile/guest icon (now-detected card and community lyrics come later).
- **Priority**: Must

### FR-11: Lyrics settings (S28)
- **Description**: Font size, show transliteration, default sync offset.
- **Priority**: Must

---

## Non-Functional Requirements

### Performance
| Requirement | Metric | Target |
|-------------|--------|--------|
| Sync accuracy | Highlight vs timing data | ±0.3 s |
| Search | Local results while typing | < 100 ms per keystroke |

### Quality
| Requirement | Standard | Notes |
|-------------|----------|-------|
| Unit tests | `dart test` in `zema_core` | Sync, play order, normalization, matching |

---

## Constraints

### Technical Constraints

**Project-wide standards**: Required standards will be loaded from memory-bank standards folder by Construction Agent

**Intent-specific constraints**:
- Normalization rules must be portable to SQL/server side in 004 (keep them as data tables, not ad-hoc code where possible).
- Do **not** reuse the old `[^a-z0-9]` regex from `SongFingerprintUtils.kt`.

### Business Constraints
- **Out of scope:** network, contributions.

---

## Assumptions

| Assumption | Risk if Invalid | Mitigation |
|------------|-----------------|------------|
| A small set of real sample songs with timings can be prepared | No realistic test data | Hand-sync 3–5 songs using local files |
| Transliteration ↔ Ethiopic can be handled by a rule table | Poor recall | Add fuzzy scoring; collect failing queries as test cases |

---

## Open Questions

| Question | Owner | Due Date | Resolution |
|----------|-------|----------|------------|
| Which sample songs (and rights to bundle their text)? | Product owner | Before bolt planning | Pending |
| Transliteration scheme to support (informal Latin spellings vs. a standard) | Product owner | Requirements review | Pending |
