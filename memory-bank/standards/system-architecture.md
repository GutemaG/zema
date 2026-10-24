# System Architecture

## Overview

High-level architectural decisions and patterns. Sources: `docs/roadmap.md` §2–3, §5 and
`docs/flutter-build-notes.md`.

## Architecture Style

**Monorepo, layered, offline-first client.**

```text
apps/mobile (Flutter)          apps/admin (Flutter web, stage 8)
   │  presentation → application (Riverpod) → data (Drift, platform channels)
   │                                │
   └───────────┬────────────────────┘
               ▼
     packages/zema_core (pure Dart)     ◄── models, lyrics, sync engine, search
               ▲                             normalization, matching, validation,
               │                             repository interfaces
     packages/zema_data (stage 4+)      ──► Supabase (Postgres + Auth + RLS)
                                             backend/ = migrations, policies, seed
apps/mobile/android (Kotlin)
   NotificationListenerService + MediaSessionManager ──EventChannel──► Dart
   Overlay (native or flutter_overlay_window; stage 7 spike decides)
```

Rules:
- `zema_core` depends on nothing Flutter- or backend-specific.
- Apps depend on repository **interfaces**. Implementations (fake, Drift cache, Supabase)
  are injected through Riverpod providers.
- Kotlin code only bridges platform capabilities. Matching and lyrics logic stays in Dart.

## Domain Model

- **Lyrics (cloud, shared):** Song, LyricSection (+ PlayOrder), Recording, SyncTiming,
  Contribution.
- **Library (device):** LocalTrack, Folder, Album, Artist, Playlist, Favorite,
  PlayHistory, SourceMatch.
- **Account:** UserBackup.

Full definitions: `docs/flutter-build-notes.md` → "Core domain model".

## API Design

No custom API server. The app talks to Supabase directly (PostgREST + RPC functions for
search). Server-side search uses the same normalization rules as `zema_core`.

## State Management

Riverpod everywhere in Dart. Playback state is owned by `audio_service`'s handler and
exposed through providers. Now-playing events from Kotlin are exposed as a
`StreamProvider`. Live position = `positionMs + (now − positionUpdatedAt)` while playing,
plus the per-recording sync offset.

## Caching Strategy

Offline-first: lyrics fetched from the cloud are cached in Drift and served from the
cache when offline. An optional "download all lyrics" fills the cache in bulk. Library,
player, cached lyrics and floating lyrics must all work without internet.

## Security Patterns

- All write permissions are enforced by backend RLS, never by the app or website alone.
- Public read of approved content only. Users read/write only their own backup and
  contributions. Moderator role is required to approve/reject.
- Privacy: only media-session metadata is read, never notification text. No audio is
  uploaded.

## Non-Functional Targets (all stages)

| Area | Target |
|---|---|
| Performance | Cold start < 2 s on mid-range phones; 60 fps lists; 1,000-track scan < 5 s |
| Battery | System callbacks only (no polling); no constant foreground work when idle |
| Accessibility | Touch targets ≥ 44 px; contrast ≥ 4.5:1; adjustable lyrics size; screen-reader labels |
| Localization | No hard-coded strings; layouts tolerate long translations and Ethiopic script |
| Quality | `zema_core` unit-tested; analyzer clean; each stage releasable |
