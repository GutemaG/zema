---
id: 003-ethiopic-normalization
unit: 001-lyrics-engine-and-display-ui
intent: 003-lyrics-engine-and-display
status: complete
priority: must
created: 2026-10-26T13:41:09Z
assigned_bolt: 010-lyrics-engine-and-display-ui
implemented: true
---

# Story: 003-ethiopic-normalization

## User Story

**As a** listener typing with any keyboard
**I want** spelling variants and noise to be ignored
**So that** I find the song however its title is written

## Acceptance Criteria

- [x] **Given** text with ሀ/ሐ/ኀ, ሰ/ሠ, አ/ዐ, ጸ/ፀ and other variant letters, **When** normalized, **Then** each folds to one form
- [x] **Given** "Official Video", "Lyrics", "New Mezmur", "ft.", a year or punctuation, **When** normalized, **Then** they are removed; Ethiopic characters are never removed
- [x] **Given** Latin text, **When** normalized, **Then** it is lower-cased and diacritics are dropped
- [x] **Given** the rules, **When** inspected, **Then** they are data tables (map + word list) exported from `zema_core`, with no `[^a-z0-9]` style regex
- [x] **Given** tests, **When** run, **Then** every fold, noise word, mixed-script and empty input is covered

## Technical Notes

- `packages/zema_core/lib/src/search/`; pure Dart, no Flutter.
- Ethiopic word separator ፡ and ። treated as spaces.

## Dependencies

### Requires
- None

### Enables
- 004-transliteration-matching
- 005-search-screen
- 011-track-song-linking

## Edge Cases

| Scenario | Expected Behavior |
|----------|-------------------|
| Only noise words | Normalizes to empty; search shows recent searches |
| Combining marks / NFC vs NFD | Normalized to NFC first |

## Out of Scope

- Transliteration (story 004)
