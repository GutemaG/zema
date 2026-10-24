---
id: 002-app-identity
unit: 001-app-foundation-ui
intent: 001-app-foundation
status: draft
priority: must
created: 2026-10-23T22:22:46Z
assigned_bolt: 001-app-foundation-ui
implemented: false
---

# Story: 002-app-identity

## User Story

**As a** listener
**I want** the installed app to be clearly named "Zema" with its own icon
**So that** I can find it on my phone

## Acceptance Criteria

- [ ] **Given** the app is installed on Android, **When** I look at the launcher, **Then** the label is "Zema"
- [ ] **Given** the app is installed, **When** I look at the launcher, **Then** a placeholder icon shows the ዜ glyph in `primary` (#E3AE4A) on `bg` (#110D0B), including an adaptive-icon variant
- [ ] **Given** the Android build config, **When** I inspect it, **Then** `applicationId` and `namespace` are `com.zemaapp.zema`
- [ ] **Given** the iOS project, **When** it builds, **Then** the display name is "Zema" (no iOS-specific work beyond that)

## Technical Notes

- `android:label` in `AndroidManifest.xml`; `CFBundleDisplayName` in iOS `Info.plist`.
- Generate icons with `flutter_launcher_icons` (dev dependency) from a 1024×1024 source PNG in `apps/mobile/assets/icon/`.
- `applicationId` is already `com.zemaapp.zema` — verify, don't change.

## Dependencies

### Requires
- None

### Enables
- None

## Edge Cases

| Scenario | Expected Behavior |
|----------|-------------------|
| Launcher uses themed/monochrome icons (Android 13+) | Monochrome layer provided or falls back gracefully |

## Out of Scope

- Final icon artwork, splash screen design
