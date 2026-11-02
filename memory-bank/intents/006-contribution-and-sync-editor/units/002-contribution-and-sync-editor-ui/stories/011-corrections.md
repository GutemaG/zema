---
id: 011-corrections
unit: 002-contribution-and-sync-editor-ui
intent: 006-contribution-and-sync-editor
status: complete
priority: must
created: '2026-11-02T07:00:52Z'
assigned_bolt: 049-contribution-and-sync-editor-ui
implemented: true
---

# Story: 011-corrections

## User Story

**As a** contributor
**I want** to fix mistakes in an approved song
**So that** the catalog gets better

## Acceptance Criteria

- [ ] **Given** Song detail of a catalog song, **When** Suggest a correction, **Then** S19 opens filled with the current song
- [ ] **Given** changed lyrics, **When** S22, **Then** changed lines are shown, and recordings that would lose timings are named
- [ ] **Given** submit, **When** pressed, **Then** an `edit_lyrics` contribution with the song ID and base version is sent

## Dependencies

### Requires
- 010-duplicate-check-and-entry-points

### Enables
- 013-moderator-queue

## Edge Cases

| Scenario | Expected Behavior |
|----------|-------------------|
| No changes made | Submit disabled |
