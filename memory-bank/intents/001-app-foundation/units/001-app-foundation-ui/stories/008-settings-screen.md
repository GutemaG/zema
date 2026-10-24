---
id: 008-settings-screen
unit: 001-app-foundation-ui
intent: 001-app-foundation
status: complete
priority: must
created: 2026-10-23T22:22:46Z
assigned_bolt: 003-app-foundation-ui
implemented: true
---

# Story: 008-settings-screen

## User Story

**As a** listener
**I want** a Settings screen with language, palette and app information
**So that** I can adjust the app and see which version I have

## Acceptance Criteria

- [ ] **Given** I tap the gear icon on Home, **When** Settings opens, **Then** it shows a General card (Language, Appearance) and an About card (Version, Open-source licenses), styled as grouped cards with value rows and ›
- [ ] **Given** the Language and Appearance rows, **When** displayed, **Then** each shows the current value (language in its own script; palette and mode localized, e.g. "Night Vigil · System")
- [ ] **Given** the Version row, **When** displayed, **Then** it shows the build's version and build number (e.g. `1.0.0 (1)`)
- [ ] **Given** I tap Open-source licenses, **When** the page opens, **Then** Flutter's license page lists packages and the two font licenses
- [ ] **Given** Settings, **When** inspected, **Then** no other S28 sections (Lyrics, Library, Playback, Account, Privacy) are present
- [ ] **Given** TalkBack and 1.3× text scale, **When** using Settings, **Then** every row is labeled, ≥ 44 px tall, and nothing overflows

## Technical Notes

- `features/settings/presentation/settings_screen.dart`; version via `package_info_plus`.
- Row tap handlers for Language/Palette open pickers implemented in 009/010 (a bottom sheet or dialog with radio options).

## Dependencies

### Requires
- 006-app-shell-and-routing (route), 004-bundled-fonts (licenses)

### Enables
- 009-switch-palette, 010-switch-language

## Edge Cases

| Scenario | Expected Behavior |
|----------|-------------------|
| `package_info_plus` fails | Row shows "—" instead of crashing |

## Out of Scope

- All other S28 sections (added by later intents)
