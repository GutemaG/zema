---
id: 006-telegram-share
unit: 002-contribution-and-sync-editor-ui
intent: 006-contribution-and-sync-editor
status: planned
priority: should
created: '2026-11-02T07:00:52Z'
assigned_bolt: 045-contribution-and-sync-editor-ui
implemented: false
---

# Story: 006-telegram-share

## User Story

**As a** contributor
**I want** to share a Telegram audio file to Zema
**So that** I can sync recordings that aren't in my library

## Acceptance Criteria

- [ ] **Given** Android and an audio file in Telegram (or any app), **When** shared to Zema, **Then** Zema copies it into its own storage and opens S20 with it selected (signing in first via C09 if needed)
- [ ] **Given** the shared file, **When** used in S21, **Then** it plays in the sync editor
- [ ] **Given** the contribution, **When** submitted, **Then** the recording's source is `telegram` with the file name and duration
- [ ] **Given** the draft, **When** deleted, or its contribution approved or rejected, **Then** the copied file is removed

## Technical Notes

- Pick `receive_sharing_intent` or `share_handler` in the plan. iOS: no share target.

## Dependencies

### Requires
- 005-link-recording

### Enables
- 007-sync-editor-list

## Edge Cases

| Scenario | Expected Behavior |
|----------|-------------------|
| Non-audio file shared | Not offered (filter `audio/*`) |
| App cold-started by the share | Opens straight to S20 |

## Out of Scope

- iOS share extension
