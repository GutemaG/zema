---
id: 008-home-community-row
unit: 002-cloud-lyrics-catalog-ui
intent: 004-cloud-lyrics-catalog
status: complete
priority: could
created: '2026-10-29T05:59:04Z'
assigned_bolt: 028-cloud-lyrics-catalog-ui
implemented: true
---

# Story: 008-home-community-row

## User Story

**As a** listener
**I want** to see newly added lyrics on Home
**So that** I discover songs

## Acceptance Criteria

- [x] **Given** the index, **When** Home shows, **Then** a row lists the most recently approved songs with a Synced or Text only badge
- [x] **Given** a card, **When** tapped, **Then** Song detail opens
- [x] **Given** an empty index, **When** Home shows, **Then** the row is hidden

## Technical Notes

- Intent done-when checks run in the same bolt.

## Dependencies

### Requires
- 002-song-index

### Enables
- None

## Edge Cases

| Scenario | Expected Behavior |
|----------|-------------------|
| Index refresh while on Home | Row updates in place |

## Out of Scope

- Personalised recommendations
