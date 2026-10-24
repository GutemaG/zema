---
id: 010-switch-language
unit: 001-app-foundation-ui
intent: 001-app-foundation
status: draft
priority: must
created: 2026-10-23T22:22:46Z
assigned_bolt: 003-app-foundation-ui
implemented: false
---

# Story: 010-switch-language

## User Story

**As a** listener
**I want** to pick English, አማርኛ, Afaan Oromoo or ትግርኛ and have the app remember it
**So that** the app stays in my language regardless of my phone's settings

## Acceptance Criteria

- [ ] **Given** Settings → Language, **When** the picker opens, **Then** it lists English, አማርኛ, Afaan Oromoo, ትግርኛ (each in its own language) with the current one selected
- [ ] **Given** I pick አማርኛ, **When** I return to any screen, **Then** all visible strings are in Amharic (English for missing keys) without a restart
- [ ] **Given** I picked a language, **When** I force-stop and relaunch, **Then** the first frame uses that language even if the device locale differs
- [ ] **Given** unit tests, **When** run, **Then** `SettingsRepository` round-trips the language and `resolveInitialLanguage` prefers the saved value

## Technical Notes

- Key `localeCode` in `shared_preferences`; `MaterialApp.router(locale: …)` from the settings provider.
- Language names are not translated (always shown in their own script).

## Dependencies

### Requires
- 005-localization-and-initial-locale, 008-settings-screen, 009-switch-palette (repository)

### Enables
- None in this intent; S01 language selector (intent 007) reuses it

## Edge Cases

| Scenario | Expected Behavior |
|----------|-------------------|
| User picks the language already active | No-op, picker closes |
| Ethiopic labels at 1.3× scale in picker | No clipping; line height ≥ 1.4 |

## Out of Scope

- "Follow system language" option (could be added later)
