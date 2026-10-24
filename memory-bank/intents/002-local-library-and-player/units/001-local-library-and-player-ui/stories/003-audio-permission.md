---
id: 003-audio-permission
unit: 001-local-library-and-player-ui
intent: 002-local-library-and-player
status: complete
priority: must
created: 2026-10-24T19:22:00Z
assigned_bolt: 004-local-library-and-player-ui
implemented: true
---

# Story: 003-audio-permission

## User Story

**As a** listener
**I want** to understand why Zema needs my audio files before I allow it
**So that** I can trust the app and still use it if I say no

## Acceptance Criteria

- [ ] **Given** Library opens for the first time without access, **When** shown, **Then** an explanation (Zema only reads audio files, nothing else) with "Allow" and "Not now" appears before the system dialog
- [ ] **Given** "Allow", **When** the system dialog grants access, **Then** the scan starts and the Library shows its results without a restart
- [ ] **Given** "Not now" or a denial, **When** any library view shows, **Then** it shows C07 with "Grant access"
- [ ] **Given** a permanent denial, **When** "Grant access" is tapped, **Then** the app's system settings open, and on returning with access the scan starts
- [ ] **Given** Android 13+, **When** requesting, **Then** `READ_MEDIA_AUDIO` is used; on Android 12 and older `READ_EXTERNAL_STORAGE`
- [ ] **Given** iOS, **When** Library opens, **Then** no permission is requested and C07 shows "Not available on iOS yet"
- [ ] **Given** tests, **When** run, **Then** a fake permission service covers granted, denied, permanently denied and returning from settings

## Technical Notes

- `permission_handler`; status re-checked on `AppLifecycleState.resumed`.
- Manifest: `READ_MEDIA_AUDIO`, `READ_EXTERNAL_STORAGE` with `maxSdkVersion=32`.

## Dependencies

### Requires
- None

### Enables
- 004-library-scan-and-sync

## Edge Cases

| Scenario | Expected Behavior |
|----------|-------------------|
| Access revoked in system settings while the app runs | On resume, views switch to the C07 grant state; stored library is not shown |
| Explanation already seen | Next time "Grant access" goes straight to the system dialog |

## Out of Scope

- Notification and overlay permissions (007)
- Onboarding S03 (007)
