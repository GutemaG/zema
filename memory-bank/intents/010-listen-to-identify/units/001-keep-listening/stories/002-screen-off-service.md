---
id: 002-screen-off-service
unit: 001-keep-listening
intent: 010-listen-to-identify
status: complete
priority: must
created: '2026-11-20T12:00:00Z'
assigned_bolt: 063-keep-listening
implemented: true
---

# Story: 002-screen-off-service

**As a** listener
**I want** it to keep working with the screen off
**So that** the phone can stay in my pocket

## Acceptance Criteria

- [x] **Given** Android, **When** it starts, **Then** a microphone foreground service shows a notification with the song, Stop, and opens the lyrics on tap
- [x] **Given** the app is closed from Recents, **Then** it stops and doesn't restart by itself
- [x] **Given** iOS, **Then** it works only while Zema is open
