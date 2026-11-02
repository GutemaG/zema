---
id: 008-sync-editor-focus-and-preview
unit: 002-contribution-and-sync-editor-ui
intent: 006-contribution-and-sync-editor
status: complete
priority: must
created: '2026-11-02T07:00:52Z'
assigned_bolt: 047-contribution-and-sync-editor-ui
implemented: true
---

# Story: 008-sync-editor-focus-and-preview

## User Story

**As a** contributor
**I want** a focus view with a big tap area, and a preview
**So that** tapping is easy and I can check the result

## Acceptance Criteria

- [ ] **Given** the List view, **When** the Focus toggle, **Then** the previous line with its time, the current line large with its block type, the next line, a large tap area and Undo / Pause / −5 s show; no counters or progress segments (design `07b-sync-focus.png`)
- [ ] **Given** either view, **When** toggled, **Then** the same timings and position carry over
- [ ] **Given** Preview, **When** pressed, **Then** playback starts from the beginning with highlighting through the shared lyrics view (C06)
- [ ] **Given** a small phone at 1.3× text, dark and light, **When** both views show, **Then** nothing overflows

## Dependencies

### Requires
- 007-sync-editor-list

### Enables
- 009-review-and-submit

## Edge Cases

| Scenario | Expected Behavior |
|----------|-------------------|
| Toggle mid-playback | Playback continues |
