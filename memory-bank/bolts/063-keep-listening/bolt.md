---
id: 063-keep-listening
unit: 001-keep-listening
intent: 010-listen-to-identify
type: simple-construction-bolt
status: complete
stories:
  - 001-listen-in-bursts
  - 002-screen-off-service
created: '2026-11-20T12:00:00Z'
started: '2026-11-20T12:00:00Z'
completed: '2026-11-20T14:00:00Z'
current_stage: null
stages_completed: [plan, implement, test]
requires_bolts: []
enables_bolts: []
requires_units: []
blocks: false
---

# Bolt: 063-keep-listening

## Overview

Keep listening: bursts of the existing Listen, kept running with the screen off by a
microphone foreground service on Android.

## Plan

- `ListenController.listen(background: true)` returns how the burst ended, keeps the found
  song on screen, and adds History only for a new song.
- `KeepListening` (Dart) runs the bursts, the pauses (`keepListeningPause`) and the time
  limit, and drives the notification.
- `KeepListeningService` (Kotlin, `foregroundServiceType="microphone"`) holds the
  notification and a wake lock; Stop and Open lyrics come back through `zema/keep_listening`
  and the launch channel.
- Listen screen: a Keep listening button with a length; the lyrics screen shows "until"
  with Stop.

## Stages

- [x] **1. plan**
- [x] **2. implement**
- [x] **3. test**

## Result

- `ListenController.listenInBackground`, `cancelBackground`, `sameMoment`.
- `KeepListening`, `keepListeningPause`; `KeepListeningService` (Dart) and
  `KeepListeningService` / `KeepListeningChannel` (Kotlin); `OpenKeepListening` launch.
- `KeepListeningBar` and its length sheet on the Listen and lyrics screens.
- Tests: `keep_listening_test.dart` (9) and 3 burst tests in `listen_controller_test.dart`.
  The release APK builds. Not yet tried on a phone (plan steps 5–6 still open).
