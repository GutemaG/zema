---
id: 004-add-lyrics-editor
unit: 002-contribution-and-sync-editor-ui
intent: 006-contribution-and-sync-editor
status: planned
priority: must
created: '2026-11-02T07:00:52Z'
assigned_bolt: 044-contribution-and-sync-editor-ui
implemented: false
---

# Story: 004-add-lyrics-editor

## User Story

**As a** contributor
**I want** to type or paste lyrics in blocks with a play order
**So that** a chorus is written once and repeated

## Acceptance Criteria

- [ ] **Given** S19, **When** opened, **Then** title, transliteration, artist and album fields and the block editor show (design `06-add-lyrics.png`)
- [ ] **Given** the block editor, **When** used, **Then** blocks (Verse/Chorus/Bridge/Other) and their lines can be added, deleted and reordered; each line can have a transliteration
- [ ] **Given** the play order strip, **When** used, **Then** entries can be added, removed and reordered; by default each block appears once in order
- [ ] **Given** Paste all text, **When** pasted, **Then** blocks and play order come from `splitPastedLyrics`, and can be changed
- [ ] **Given** invalid lyrics, **When** Next is pressed, **Then** it stays disabled and the field shows the error
- [ ] **Given** a small phone at 1.3× text, dark and light, **When** S19 shows, **Then** nothing overflows

## Technical Notes

- Ethiopic input via the system keyboard; no custom keyboard.

## Dependencies

### Requires
- 003-contribute-tab-and-drafts

### Enables
- 005-link-recording

## Edge Cases

| Scenario | Expected Behavior |
|----------|-------------------|
| Delete a block used in the play order | Its entries are removed too, after confirmation |

## Out of Scope

- Duplicate check (010)
