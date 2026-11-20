---
id: 064-float-player-lyrics
unit: null
intent: 009-audio-fingerprint-library
type: simple-construction-bolt
status: complete
stories: []
created: '2026-11-20T16:00:00Z'
started: '2026-11-20T16:00:00Z'
completed: '2026-11-20T17:00:00Z'
current_stage: null
stages_completed: [plan, implement, test]
requires_bolts: []
enables_bolts: []
requires_units: []
blocks: false
---

# Bolt: 064-float-player-lyrics

## Overview

FR-14's floating lyrics for songs played in Zema itself (Android): a song with lyrics
floats when the user leaves Zema, by default.

## Built

- `playerOverlayProvider`: the current track's lyrics as an `OverlaySheet` (source
  `zema`, key `player:{trackId}`), timed like the lyrics view (offset = −shift).
- `lyricsOverlaySyncProvider` shows it when wanted (the user's choice for that track, else
  Settings → Other apps → "Float lyrics when I leave Zema", on by default). Zema playing
  wins over a detected app; paused, a detected song wins. Close hides it until the next
  track. A timing change in the panel is saved as the recording's own offset.
- `playerOverlayClockProvider` sends play, pause, seek and track changes (and drift over
  0.7 s) through the new `clock` overlay method; `LyricsOverlay.setClock` keeps a clock
  per source, since Android doesn't report Zema's own session to the overlay.
- Song menu: "Float lyrics" for linked songs (asks for the overlay permission if missing;
  plays the song next and skips to it when it isn't the current one).
- The headless overlay engine overrides `playerOverlayProvider` with null (no player there).

## Tests

`test/features/detection/player_overlay_test.dart`: floats by default, Close for one song
only, the setting off with Float lyrics, priority over a detected app. Not checked on a
phone.
