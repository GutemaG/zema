---
id: 011-folders
unit: 001-local-library-and-player-ui
intent: 002-local-library-and-player
status: draft
priority: must
created: 2026-10-24T19:22:00Z
assigned_bolt: 006-local-library-and-player-ui
implemented: false
---

# Story: 011-folders

## User Story

**As a** listener
**I want** to browse songs by folder
**So that** I can find Telegram or WhatsApp audio where it was saved

## Acceptance Criteria

- [ ] **Given** Folders, **When** shown, **Then** every folder containing visible audio shows with name, song count and path
- [ ] **Given** a folder, **When** opened (S11a), **Then** a breadcrumb path, subfolders first, then tracks, with Play all and Shuffle
- [ ] **Given** a breadcrumb segment, **When** tapped, **Then** that folder opens
- [ ] **Given** a folder's menu, **When** Hide is chosen, **Then** its tracks disappear everywhere with an undo snackbar
- [ ] **Given** no folders, **When** shown, **Then** C07 empty

## Technical Notes

- Folder tree derived from track paths; the root is the storage volume (`/storage/emulated/0`), shown as "Phone".

## Dependencies

### Requires
- 004-library-scan-and-sync

### Enables
- 020-library-settings

## Edge Cases

| Scenario | Expected Behavior |
|----------|-------------------|
| Folder with only subfolders | Listed with the count of all songs below it |
| Folder name in Ethiopic | Shown with the Ethiopic line height |
