---
id: 004-transliteration-matching
unit: 001-lyrics-engine-and-display-ui
intent: 003-lyrics-engine-and-display
status: complete
priority: must
created: 2026-10-26T13:41:09Z
assigned_bolt: 010-lyrics-engine-and-display-ui
implemented: true
---

# Story: 004-transliteration-matching

## User Story

**As a** listener with a Latin keyboard
**I want** to type a song name the way I say it
**So that** I can find Ethiopic titles without an Ethiopic keyboard

## Acceptance Criteria

- [x] **Given** an Ethiopic word, **When** converted, **Then** a rule table maps each syllable to a Latin consonant skeleton ("ቅድስት" → "kdst")
- [x] **Given** a Latin query, **When** converted, **Then** vowels are dropped and q/k, ts/s, ch/c and doubled letters fold the same way
- [x] **Given** "kidist", "qidist", "kiddist", **When** matched against "ቅድስት" and "ቅዱስት", **Then** all match; "egziabher" matches "እግዚአብሔር"; "selam" matches "ሰላም"
- [x] **Given** unrelated words with the same skeleton length, **When** matched, **Then** the fuzzy score ranks them below exact skeleton matches and below a threshold
- [x] **Given** tests, **When** run, **Then** a table of query/target pairs (matches and non-matches) is checked

## Technical Notes

- Skeleton + edit-distance score; table kept as data for 004 (SQL side).

## Dependencies

### Requires
- 003-ethiopic-normalization

### Enables
- 005-search-screen
- 011-track-song-linking

## Edge Cases

| Scenario | Expected Behavior |
|----------|-------------------|
| Mixed Latin and Ethiopic query | Each word compared in its own script |
| Very short query (1–2 letters) | Prefix match only, no fuzzy |

## Out of Scope

- Typing Ethiopic with a Latin keyboard (input method)
