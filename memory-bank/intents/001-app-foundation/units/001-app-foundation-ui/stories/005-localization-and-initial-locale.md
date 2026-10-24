---
id: 005-localization-and-initial-locale
unit: 001-app-foundation-ui
intent: 001-app-foundation
status: draft
priority: must
created: 2026-10-23T22:22:46Z
assigned_bolt: 002-app-foundation-ui
implemented: false
---

# Story: 005-localization-and-initial-locale

## User Story

**As a** listener whose phone is set to Amharic, Afaan Oromoo or Tigrinya
**I want** the app to start in my language automatically
**So that** I don't have to find a language setting in a language I may not read

## Acceptance Criteria

- [ ] **Given** ARB files `app_en.arb`, `app_am.arb`, `app_om.arb`, `app_ti.arb`, **When** l10n is generated, **Then** English has every key and the others fall back to English for missing keys
- [ ] **Given** no saved language and a device locale of `am`, **When** the app launches, **Then** the UI is Amharic (English for missing keys)
- [ ] **Given** no saved language and a device locale of `fr`, **When** the app launches, **Then** the UI is English
- [ ] **Given** device locale `om`, **When** Material widgets (dialogs, back tooltips) render, **Then** they do not crash and show English built-in strings
- [ ] **Given** a saved language, **When** the app launches, **Then** the saved language wins over the device locale
- [ ] **Given** widgets under `lib/`, **When** a test scans for user-visible string literals in `Text(...)`, tooltips and semantic labels, **Then** none are found

## Technical Notes

- `flutter: generate: true` + `l10n.yaml`; keys lowerCamelCase, screen-prefixed (`navHome`, `settingsLanguageTitle`).
- `resolveInitialLanguage(saved, deviceLocales)` as a pure function with unit tests (covers region variants like `am_ET`).
- Fallback `LocalizationsDelegate<MaterialLocalizations>`/`Cupertino` for `om` (and `ti` if Flutter lacks it) delegating to English.
- At minimum translate nav labels and "Coming soon" in am/om/ti if text is available; otherwise English fallback is acceptable.

## Dependencies

### Requires
- None (uses settings value from 010 later; until then saved language = null)

### Enables
- 006, 007, 008, 010

## Edge Cases

| Scenario | Expected Behavior |
|----------|-------------------|
| Device locale list has `en_US` first, `am` second | Use first supported → English |
| Saved value is an unknown code | Ignored; resolve from device |

## Out of Scope

- Full translations of all strings (content work, not engineering)
- RTL (none of the four languages need it)
