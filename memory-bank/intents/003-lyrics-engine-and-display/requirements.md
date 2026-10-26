---
intent: 003-lyrics-engine-and-display
phase: inception
status: units-defined
created: 2026-10-23T22:16:40Z
updated: 2026-10-26T13:41:09Z
---

# Requirements: Lyrics Engine and Display

> Source: `docs/roadmap.md` Stage 3 · screens: `docs/screens.md` S05, S06, S07, S08, S28,
> C06 · domain model: `docs/flutter-build-notes.md` · Complexity ★★★☆☆ · No network
> (bundled sample data).

## Intent Overview

Replace the Home and Search "Coming soon" tabs with working screens, then show synced
lyrics for local songs using bundled sample data, proving the lyrics model, sync engine
and Ethiopic search before any backend exists. Home and Search come first (they need no
lyrics); the lyrics pieces follow in small bolts.

## Business Goals

| Goal | Success Metric | Priority |
|------|----------------|----------|
| No "Coming soon" on Home and Search | Both tabs show real content offline | Must |
| Accurate synced lyrics | Lines highlighted within ±0.3 s of timing data | Must |
| Search works with any keyboard | "kidist", "ቅድስት", "ቅዱስት" find the same song | Must |
| Proven core logic | Unit tests cover sync engine, play order, normalization, LRC import, matching | Must |

---

## Functional Requirements

### FR-1: Home (S05)
- **Description**: Header with a search shortcut (→ Search tab) and the existing Settings
  button. Quick actions: Shuffle all, Favorites, Recently added, Playlists. Continue
  listening: the restored last queue's current song with its position and a resume
  button. Recently played: a horizontal row of the latest plays (from intent 002's
  history). Your playlists: a horizontal row → playlist page.
- **Acceptance Criteria**: Each section hides when it has nothing to show; with no audio
  access or an empty library, Home shows the C07 state with the permission or rescan
  action; resume continues from the saved position; 1.3× text and both themes without
  overflow.
- **Priority**: Must
- **Out of scope here**: now-detected card (007), community lyrics row (004), profile /
  guest icon (005).

### FR-2: Ethiopic search normalization (`zema_core`)
- **Description**: Fold Ethiopic letter variants (ሀ/ሐ/ኀ, ሰ/ሠ, አ/ዐ, ጸ/ፀ, ቀ-ቐ …) and
  vowel orders where they are spelling variants; lower-case; drop punctuation and
  noise ("Official Video", "Lyrics", "New Mezmur", years, "ft."). Unicode-safe: never
  strips Ethiopic characters.
- **Acceptance Criteria**: Folding rules live in data tables, not ad-hoc code; unit tests
  for each fold, noise word and mixed-script input; the old `[^a-z0-9]` regex is not used.
- **Priority**: Must

### FR-3: Transliteration matching (`zema_core`)
- **Description**: Match informal Latin spellings to Ethiopic text: a rule table maps
  Ethiopic syllables to Latin consonant skeletons ("ቅድስት" → "kdst"), and queries are
  compared by skeleton plus a fuzzy score, so "kidist", "qidist", "kiddist" all match.
- **Acceptance Criteria**: Test cases "kidist"/"ቅድስት"/"ቅዱስት", "egziabher"/"እግዚአብሔር",
  "selam"/"ሰላም" match; unrelated words don't; failing real queries are added as cases.
- **Priority**: Must

### FR-4: Search (S06)
- **Description**: One field, results while typing across the local library (songs,
  artists, albums) and, once lyrics exist, lyric text. Scope chips All, Songs, Artists,
  Albums, Lyrics. Results grouped by type; song rows play on tap and have the song menu.
  Recent searches (clearable) when the field is empty; C07 no-results state.
- **Acceptance Criteria**: < 100 ms per keystroke on 1,000 tracks; uses FR-2 and FR-3;
  recent searches kept across restarts (max 10).
- **Priority**: Must
- **Out of scope here**: cloud catalog (004), "Add this song's lyrics" (006), popular songs.

### FR-5: Lyrics domain models (`zema_core`)
- **Description**: Song (title, transliteration, artist, album), LyricSection
  (verse / chorus / bridge + lines), PlayOrder, Recording (artist, source, duration,
  offset), SyncTiming as immutable pure-Dart models with JSON.
- **Priority**: Must

### FR-6: Play-order expansion
- **Description**: Expand PlayOrder into a flat sequence of line occurrences (chorus
  written once, repeated); each occurrence addressable for timing.
- **Acceptance Criteria**: Unit tests for repeated chorus, bridge, empty sections.
- **Priority**: Must

### FR-7: Sync engine
- **Description**: Given position + per-recording offset → current line occurrence
  index and the next line; handles seek, pre-first-line and after-last-line.
- **Acceptance Criteria**: Correct within ±0.3 s; unit-tested including boundaries.
- **Priority**: Must

### FR-8: LRC import
- **Description**: Convert LRC text (`[mm:ss.xx] line`, multiple tags per line, offset
  tag) into a Song + Recording + SyncTiming; repeated lines become a chorus where they
  repeat as a block.
- **Acceptance Criteria**: Unit tests for multi-tag lines, offset, malformed lines
  (skipped and reported), and Ethiopic text.
- **Priority**: Must

### FR-9: `LyricsRepository` + bundled sample data
- **Description**: Interface in `zema_core`; `BundledLyricsRepository` loads 3–5
  placeholder songs (original text written for Zema, Amharic and Afaan Oromoo) from
  app assets, timed with LRC to generated test audio that can be pushed to a device.
  Real songs can be added later in the same format without code changes.
- **Priority**: Must

### FR-10: Link local tracks to songs
- **Description**: Automatic match by normalized title + artist (FR-2/FR-3); manual
  "Match lyrics" from the song menu with a search picker; "Unlink"; matches saved in
  Drift (schema v2 with a migration test).
- **Acceptance Criteria**: Automatic match only above a confidence threshold; a manual
  match always wins and survives rescans.
- **Priority**: Must

### FR-11: Lyrics view (C06) in Now Playing (S08)
- **Description**: Current line highlighted (`primaryText`) and auto-scrolled; past
  lines dimmed (`faint`); tap a line to seek; chorus markers; transliteration toggle;
  font size; per-recording sync offset ±0.5 s steps; auto-scroll pauses on manual
  scroll and resumes after 3 s; plain-text fallback without timing; "No lyrics" state
  with Match.
- **Priority**: Must

### FR-12: Song detail (S07) — Lyrics and Info tabs
- **Description**: Header (title, transliteration, artist, album) with Play, favorite,
  add to playlist; Lyrics tab with structured sections and ↻ repeat markers and font
  size; Info tab with album, artist and source. Opened from the song menu ("View
  lyrics") and from lyric search results.
- **Priority**: Must

### FR-13: Lyrics settings (S28)
- **Description**: Lyrics section in Settings: font size, show transliteration, default
  sync offset.
- **Acceptance Criteria**: Values persist and apply to C06 immediately.
- **Priority**: Must

---

## Non-Functional Requirements

### Performance
| Requirement | Metric | Target |
|-------------|--------|--------|
| Sync accuracy | Highlight vs timing data | ±0.3 s |
| Search | Local results while typing (1,000 tracks) | < 100 ms per keystroke |
| Home | Stored data on screen after launch | < 1 s |

### Quality
| Requirement | Standard | Notes |
|-------------|----------|-------|
| Unit tests | `dart test` in `zema_core` | Sync, play order, normalization, transliteration, LRC, matching |
| Widget tests | `flutter test` | Home, Search, C06, S07, settings; 1.3× and both themes |

---

## Constraints

### Technical Constraints

**Project-wide standards**: Required standards will be loaded from memory-bank standards folder by Construction Agent

**Intent-specific constraints**:
- Normalization and transliteration rules must be portable to SQL/server side in 004
  (keep them as data tables, not ad-hoc code).
- Do **not** reuse the old `[^a-z0-9]` regex from `SongFingerprintUtils.kt`.
- Bolts stay small (1–3 stories) so each can be finished in one session.

### Business Constraints
- **Out of scope:** network, contributions, the Contribute tab (stays "Coming soon"
  until 006), accounts.

---

## Assumptions

| Assumption | Risk if Invalid | Mitigation |
|------------|-----------------|------------|
| Placeholder songs timed to generated audio are realistic enough | Sync issues only seen with real songs | Format accepts real songs later; check one real song by hand when available |
| Transliteration ↔ Ethiopic can be handled by a rule table | Poor recall | Fuzzy scoring; collect failing queries as test cases |

---

## Resolved Questions

| Question | Resolution | Date |
|----------|------------|------|
| Which sample songs (and rights to bundle their text)? | Original placeholder lyrics written for Zema; real songs added later in the same format | 2026-10-26T13:41:09Z |
| Transliteration scheme | Informal Latin spellings (rule table + fuzzy), not a fixed standard | 2026-10-26T13:41:09Z |
| Home in this intent? | Yes, built first | 2026-10-26T13:41:09Z |
| How are sample timings written before the sync editor (006)? | LRC, converted by an importer (FR-8) | 2026-10-26T13:41:09Z |
