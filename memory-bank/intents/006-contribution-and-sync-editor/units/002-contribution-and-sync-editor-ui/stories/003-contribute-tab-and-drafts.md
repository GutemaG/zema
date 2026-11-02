---
id: 003-contribute-tab-and-drafts
unit: 002-contribution-and-sync-editor-ui
intent: 006-contribution-and-sync-editor
status: complete
priority: must
created: '2026-11-02T07:00:52Z'
assigned_bolt: 043-contribution-and-sync-editor-ui
implemented: true
---

# Story: 003-contribute-tab-and-drafts

## User Story

**As a** contributor
**I want** a Contribute tab that explains how it works and keeps my unfinished work
**So that** I can come back to a draft any time

## Acceptance Criteria

- [x] **Given** a guest, **When** they open the tab, **Then** S05 explains contributing; Add lyrics and My contributions open C09; after sign-in the action continues
- [x] **Given** a signed-in user, **When** they open the tab, **Then** S05 shows the steps, Add lyrics, their drafts (title, last changed, step) and My contributions
- [x] **Given** any change in the flow, **When** made, **Then** the draft is saved in Drift (schema v8) within a second; killing the app loses nothing
- [x] **Given** a draft, **When** opened or deleted (with confirmation), **Then** it continues at its step, or is removed
- [x] **Given** drafts exist, **When** the user signs out, **Then** a warning names them; confirming deletes them
- [x] **Given** no backend in the build, **When** the tab opens, **Then** the Contribute actions are hidden

## Technical Notes

- Design `05-contribute.png`. Drafts store the zema_core draft as JSON plus step and timestamps.

## Dependencies

### Requires
- 002-contribution-repository

### Enables
- 004-add-lyrics-editor

## Edge Cases

| Scenario | Expected Behavior |
|----------|-------------------|
| Two drafts with the same title | Both listed, newest first |

## Out of Scope

- Backing up drafts
