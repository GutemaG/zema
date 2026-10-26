---
intent: 003-lyrics-engine-and-display
phase: inception
status: context-defined
updated: 2026-10-26T13:41:09Z
---

# Lyrics Engine and Display - System Context

## System Overview

Home, Search, the lyrics view on Now Playing, Song detail and a Lyrics section in
Settings, inside the existing Zema app (`apps/mobile`, intents 001–002). Lyrics come
from sample data bundled as app assets; the pure lyrics logic (models, play order, sync
engine, normalization, transliteration, LRC import) lives in `packages/zema_core` so the
cloud catalog (004) and the server can reuse it. Fully offline. No backend.

## Actors

- **Listener** (Human): opens Home, searches with an Ethiopic or Latin keyboard, reads
  synced lyrics while a song plays, links a song to its lyrics, adjusts font size and
  sync offset. May use TalkBack or a large font scale.
- **Player** (Internal, intent 002): provides the current track, position and playing
  state; accepts seek and play commands.

## Context Diagram

```mermaid
C4Context
    title System Context - 003-lyrics-engine-and-display

    Person(listener, "Listener", "Reads lyrics, searches, browses Home")

    System(app, "Zema app", "Home, Search, lyrics view, Song detail, Settings")

    System_Int(player, "Player (002)", "Current track, position, seek")
    SystemDb(assets, "App assets", "Bundled sample lyrics (JSON + LRC)")
    SystemDb(db, "Drift database", "Tracks, history, track-to-song links (schema v2)")
    SystemDb_Ext(prefs, "shared_preferences", "Lyrics settings, recent searches, offsets")

    Rel(listener, app, "Searches, reads, links")
    Rel(app, player, "Reads position, seeks")
    Rel(app, assets, "Loads sample songs")
    Rel(app, db, "Reads library, writes links")
    Rel(app, prefs, "Reads and writes settings")
```

## External Integrations

- **App assets**: `assets/lyrics/` with one file per sample song (LRC + metadata JSON).
- **Drift**: schema v2 adds a track-to-song link table; migration v1 → v2 tested.
- **shared_preferences** (existing `SettingsRepository`): font size, transliteration,
  default offset, per-recording offsets, recent searches.
- **Network**: none.

## Data Flows

### Inbound
- **Sample lyrics** (assets → app): parsed once at start-up into Songs, Recordings and
  SyncTimings; malformed files are skipped and logged.
- **Playback position** (player → lyrics view): position stream + playing state.

### Outbound
- **Seek** (lyrics view → player): tapping a line seeks to its timing.
- **Links** (app → Drift): automatic and manual track-to-song links.
- **Settings** (app → shared_preferences).

## High-Level Constraints

- Normalization and transliteration rules are data tables portable to SQL (004).
- Lyrics text is never logged above `FINE`.
- Contribute tab stays "Coming soon" (006).

## Key NFR Goals

- Highlight within ±0.3 s of timing data.
- Search < 100 ms per keystroke on 1,000 tracks.
