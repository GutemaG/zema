---
id: 008-media-notification
unit: 001-local-library-and-player-ui
intent: 002-local-library-and-player
status: draft
priority: must
created: 2026-10-24T19:22:00Z
assigned_bolt: 005-local-library-and-player-ui
implemented: false
---

# Story: 008-media-notification

## User Story

**As a** listener
**I want** to control music from the notification, lock screen and my headphones
**So that** I can listen with the phone in my pocket

## Acceptance Criteria

- [ ] **Given** playback, **When** the app goes to the background or the screen turns off, **Then** music continues and a media notification shows art, title, artist, previous / play-pause / next and a seek bar
- [ ] **Given** the lock screen, **When** shown, **Then** the same controls work
- [ ] **Given** a headset or Bluetooth device, **When** its play/pause, next or previous buttons are pressed, **Then** the player responds
- [ ] **Given** paused, **When** the notification is dismissed, **Then** the service stops
- [ ] **Given** a phone call or another app taking audio focus, **When** it happens, **Then** playback pauses and resumes after a transient loss (the Lower volume option comes in 021)
- [ ] **Given** headphones are unplugged, **When** playing, **Then** playback pauses
- [ ] **Given** a real phone with battery saver on, **When** playing with the screen off for 30 minutes, **Then** playback is not interrupted (checked by hand; documented if an OEM needs a setting)

## Technical Notes

- `audio_service` foreground service config in `AndroidManifest.xml` (`FOREGROUND_SERVICE_MEDIA_PLAYBACK`), `audio_session` for focus and becoming-noisy.
- Notification channel name localized.

## Dependencies

### Requires
- 006-playback-engine

### Enables
- 021-playback-settings

## Edge Cases

| Scenario | Expected Behavior |
|----------|-------------------|
| App swiped away while playing | Playback continues with the notification |
| Notification art missing | App icon used |

## Out of Scope

- Android Auto, Wear OS
