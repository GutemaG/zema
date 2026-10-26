---
id: 006-recent-searches
unit: 001-lyrics-engine-and-display-ui
intent: 003-lyrics-engine-and-display
status: draft
priority: must
created: 2026-10-26T13:41:09Z
assigned_bolt: 011-lyrics-engine-and-display-ui
implemented: false
---

# Story: 006-recent-searches

## User Story

**As a** listener
**I want** my recent searches when the field is empty
**So that** I can repeat a search with one tap

## Acceptance Criteria

- [ ] **Given** I open a result or submit a query, **When** done, **Then** the query is saved to recent searches (newest first, max 10, no duplicates by normalized form)
- [ ] **Given** an empty field, **When** Search shows, **Then** recent searches list with a remove button each and Clear all
- [ ] **Given** a restart, **When** Search shows, **Then** recent searches are kept
- [ ] **Given** no recent searches, **When** the field is empty, **Then** a short hint shows instead

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
