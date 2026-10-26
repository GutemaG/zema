---
id: 006-recent-searches
unit: 001-lyrics-engine-and-display-ui
intent: 003-lyrics-engine-and-display
status: complete
priority: must
created: 2026-10-26T13:41:09Z
assigned_bolt: 011-lyrics-engine-and-display-ui
implemented: true
---

# Story: 006-recent-searches

## User Story

**As a** listener
**I want** my recent searches when the field is empty
**So that** I can repeat a search with one tap

## Acceptance Criteria

- [x] **Given** I open a result or submit a query, **When** done, **Then** the query is saved to recent searches (newest first, max 10, no duplicates by normalized form)
- [x] **Given** an empty field, **When** Search shows, **Then** recent searches list with a remove button each and Clear all
- [x] **Given** a restart, **When** Search shows, **Then** recent searches are kept
- [x] **Given** no recent searches, **When** the field is empty, **Then** a short hint shows instead

## Technical Notes

- Stored in `SettingsRepository` (shared_preferences).

## Dependencies

### Requires
- 005-search-screen

### Enables
- None

## Edge Cases

| Scenario | Expected Behavior |
|----------|-------------------|
| Query of only spaces | Not saved |

## Out of Scope

- Search suggestions
