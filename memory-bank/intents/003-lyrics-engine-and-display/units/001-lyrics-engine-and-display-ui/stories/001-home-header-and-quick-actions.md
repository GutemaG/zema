---
id: 001-home-header-and-quick-actions
unit: 001-lyrics-engine-and-display-ui
intent: 003-lyrics-engine-and-display
status: complete
priority: must
created: 2026-10-26T13:41:09Z
assigned_bolt: 009-lyrics-engine-and-display-ui
implemented: true
---

# Story: 001-home-header-and-quick-actions

## User Story

**As a** listener
**I want** Home to open the things I use most in one tap
**So that** I don't have to dig through the Library tabs

## Acceptance Criteria

- [x] **Given** Home, **When** shown, **Then** the header has a search shortcut that opens the Search tab and the Settings button
- [x] **Given** Home, **When** shown, **Then** quick actions Shuffle all, Favorites, Recently added and Playlists appear; Shuffle all plays the visible library shuffled, the others open their pages
- [x] **Given** no audio access, **When** Home shows, **Then** it shows the C07 permission state with the same flow as Library
- [x] **Given** an empty library after a scan, **When** Home shows, **Then** it shows the C07 empty state with Rescan
- [x] **Given** 1.3× text in light and dark, **When** Home shows, **Then** nothing overflows

## Technical Notes

- Replaces the "Coming soon" body of `home_screen.dart`; reuses library providers and routes from 002.
- Quick actions are a wrapping grid so long Ethiopic labels fit.

## Dependencies

### Requires
- None

### Enables
- 002-home-continue-and-recent-rows
- 005-search-screen

## Edge Cases

| Scenario | Expected Behavior |
|----------|-------------------|
| Library still scanning | Quick actions show; sections below show a progress state |
| Shuffle all with nothing playable | Button disabled |

## Out of Scope

- Now-detected card (007), community lyrics (004), profile / guest icon (005)
