---
id: 021-playback-settings
unit: 001-local-library-and-player-ui
intent: 002-local-library-and-player
status: draft
priority: must
created: 2026-10-24T19:22:00Z
assigned_bolt: 008-local-library-and-player-ui
implemented: false
---

# Story: 021-playback-settings

## User Story

**As a** listener
**I want** to set how playback behaves
**So that** Zema fits how I listen

## Acceptance Criteria

- [ ] **Given** Settings, **When** shown, **Then** a Playback section sits after Library
- [ ] **Given** Sleep timer default, **When** set, **Then** C05 preselects it
- [ ] **Given** Pause when headphones are unplugged (default on), **When** off, **Then** unplugging doesn't pause
- [ ] **Given** When another app plays sound (Pause / Lower volume; default Pause), **When** Lower volume is chosen, **Then** short interruptions duck the volume instead of pausing; calls still pause
- [ ] **Given** Gapless playback (default on), **When** on, **Then** consecutive tracks play without a gap (Should)
- [ ] **Given** a restart, **When** Settings shows, **Then** all values are kept

## Technical Notes

- Keys in `SettingsRepository`: `sleepTimerDefault`, `pauseOnUnplug`, `duckOnInterruption`, `gapless`.
- Gapless via `just_audio` concatenated sources; if it complicates the queue, defer and note it.

## Dependencies

### Requires
- 008-media-notification
- 010-sleep-timer

### Enables
- None

## Out of Scope

- Equalizer
- Crossfade
