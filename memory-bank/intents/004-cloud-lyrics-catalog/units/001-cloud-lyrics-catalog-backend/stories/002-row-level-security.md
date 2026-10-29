---
id: 002-row-level-security
unit: 001-cloud-lyrics-catalog-backend
intent: 004-cloud-lyrics-catalog
status: complete
priority: must
created: '2026-10-29T05:59:04Z'
assigned_bolt: 019-cloud-lyrics-catalog-backend
implemented: true
---

# Story: 002-row-level-security

## User Story

**As a** listener
**I want** to read only approved lyrics, and nobody to change them anonymously
**So that** the catalog stays trustworthy

## Acceptance Criteria

- [x] **Given** the anonymous role, **When** reading songs, sections, lines, recordings and timings, **Then** only rows of approved songs are returned
- [x] **Given** the anonymous role, **When** reading reports, contributions or roles, **Then** nothing is returned
- [x] **Given** the anonymous role, **When** inserting, updating or deleting on any table, **Then** it fails
- [x] **Given** pgTAP, **When** run, **Then** each rule above has a test that switches to the `anon` role

## Technical Notes

- RLS enabled on every table; policies only for SELECT of approved content.

## Dependencies

### Requires
- 001-local-supabase-and-schema

### Enables
- 003-report-function

## Edge Cases

| Scenario | Expected Behavior |
|----------|-------------------|
| A song moves from approved back to draft | Its rows stop being readable at once |

## Out of Scope

- Authenticated roles (005)
