---
id: 007-shared-empty-state-component
unit: 001-app-foundation-ui
intent: 001-app-foundation
status: draft
priority: must
created: 2026-10-23T22:22:46Z
assigned_bolt: 002-app-foundation-ui
implemented: false
---

# Story: 007-shared-empty-state-component

## User Story

**As a** listener
**I want** a clear, consistent message when a screen has nothing to show yet
**So that** I understand the app is working and what comes next

## Acceptance Criteria

- [ ] **Given** the C07 component in `lib/shared/widgets/`, **When** used with kind `empty`, `error` or `offline`, **Then** it shows the matching icon, a title, a message and an optional action button
- [ ] **Given** an `onAction` callback and label, **When** the button is tapped, **Then** the callback fires; **Given** none, **Then** no button is rendered
- [ ] **Given** each of the four tabs, **When** opened, **Then** C07 (`empty`) shows a localized "Coming soon" title and a short tab-specific message
- [ ] **Given** widget tests, **When** run, **Then** every kind is covered with and without an action, in English and with an Ethiopic string
- [ ] **Given** 1.3× text scale or +40% long strings, **When** rendered on a 360 dp wide screen, **Then** no overflow errors occur

## Technical Notes

- Colors only from `ZemaColors` (`muted` icon/message, `text` title, `primary` button).
- Centered, scrollable if content exceeds height; button ≥ 44 px tall.

## Dependencies

### Requires
- 003-theme-tokens-and-palettes, 005-localization-and-initial-locale

### Enables
- 006 (unknown-route error state), later intents' empty/error/offline screens

## Edge Cases

| Scenario | Expected Behavior |
|----------|-------------------|
| Very short screen (landscape) | Content scrolls instead of overflowing |

## Out of Scope

- Illustrations; retry logic (callers own the action)
