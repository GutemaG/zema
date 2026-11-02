---
id: 002-contribution-repository
unit: 002-contribution-and-sync-editor-ui
intent: 006-contribution-and-sync-editor
status: planned
priority: must
created: '2026-11-02T07:00:52Z'
assigned_bolt: 042-contribution-and-sync-editor-ui
implemented: false
---

# Story: 002-contribution-repository

## User Story

**As a** developer
**I want** a repository for submitting, listing and reviewing contributions
**So that** screens and tests don't depend on Supabase

## Acceptance Criteria

- [ ] **Given** the `ContributionRepository` interface in `zema_core`, **When** implemented in `zema_data`, **Then** it offers `submit`, `resubmit`, `mine`, `queue`, `review`, and `isModerator`
- [ ] **Given** server errors (rules, limits, already reviewed, offline), **When** returned, **Then** they map to typed failures the UI can name
- [ ] **Given** a fake repository, **When** used in tests, **Then** it keeps rows in memory with the same rules
- [ ] **Given** the local backend, **When** the `zema_data` integration tests run, **Then** submit → queue → review → mine works end to end

## Technical Notes

- Follow the 005 backup repository's shape and failure mapping.

## Dependencies

### Requires
- 001-contribution-model-and-validation
- 001-submit-contributions (backend)
- 002-review-and-moderator-role (backend)

### Enables
- 003-contribute-tab-and-drafts
- 009-review-and-submit

## Edge Cases

| Scenario | Expected Behavior |
|----------|-------------------|
| Session expired | Auth failure, the UI offers sign-in |

## Out of Scope

- Screens
