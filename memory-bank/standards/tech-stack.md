# Tech Stack

## Overview

Zema is an Android-first Flutter app with a pure-Dart shared core, a thin native Kotlin
layer for things Flutter cannot do (background playback detection, overlay), and a
Supabase backend added in stage 4. The stack favors offline-first behavior on mid/low-end
phones and full Ethiopic-script support.

Sources: `docs/roadmap.md` §2, `docs/flutter-build-notes.md`. Proposed defaults in the
roadmap were confirmed on 2026-10-23.

## Languages

- **Dart 3.13** (SDK `^3.13.5`): app, shared logic, admin website.
- **Kotlin**: only for the Android playback-detection listener and (depending on the
  stage 7 spike) the floating overlay. Lives in `apps/mobile/android/app/src/main/kotlin/`.
- **SQL** (Postgres): backend schema, migrations and RLS policies in `backend/`.

One language for almost everything keeps logic shareable between the mobile app, admin
site and tests. Kotlin is limited to the platform-channel boundary.

## Framework

- **Flutter 3.47** for `apps/mobile` (Android/iOS) and `apps/admin` (Flutter web).
- **State management:** Riverpod. Testable, and services don't need `BuildContext`.
- **Navigation:** go_router. Deep links and nested tab navigation (bottom nav with
  Home / Search / Library / Contribute).
- **Audio:** `just_audio` + `audio_service`. Background playback with notification and
  lock-screen controls.
- **Library scan:** a small Kotlin `MethodChannel` (`com.zemaapp.zema/library`) over
  Android MediaStore, behind the Dart `LibraryScanner` interface. Albums, artists and
  folders are derived in Dart. (Decided 2026-10-24 by the bolt 004 spike:
  `on_audio_query` 2.9.0 doesn't build with Android Gradle Plugin 9.1, because it has
  no `namespace`.)
- **Permissions:** `permission_handler` 12.x. Version 13 needs compile SDK 37, which is
  above Flutter 3.47's default and AGP 9.1's supported maximum of 36.
- **Localization:** `flutter_localizations` + ARB files (en, am, om, ti). English is
  complete first; the others fall back to English.
- **Theme:** System / Light / Dark (default System). A `ZemaColors` `ThemeExtension` with
  two palettes, Night Vigil (default) and Night Vigil · Wine, each in a dark and a light
  version; palette and theme mode are separate settings (decided 2026-10-24).
- **Fonts:** Inter + Noto Sans Ethiopic, bundled as assets (never fetched at runtime).
- **Native bridge:** `MethodChannel` (permissions, open settings, show/hide overlay) and
  `EventChannel` (now-playing events). Event format: `docs/flutter-build-notes.md`.
- **Overlay:** `flutter_overlay_window` **or** a native Kotlin overlay. To be decided
  by the stage 7 spike.

iOS is limited to the in-app player and lyrics: iOS cannot read other apps' playback or
draw overlays.

## Data

- **On device:** Drift (SQLite). Library data (playlists, favorites, play history,
  source matches, settings) and a cache of cloud lyrics for offline use.
- **Cloud (stage 4+):** Supabase. Postgres, Auth, and Row Level Security. A relational
  model fits songs/sections/recordings/timings, and the server can run search with the
  same Ethiopic normalization rules.
- **Client:** `supabase_flutter`, implemented in `packages/zema_data` behind the
  repository interfaces defined in `packages/zema_core`.

## Authentication

**Google sign-in only** (via Supabase Auth). No passwords, phone or OTP. Guest mode is
the default; sign-in is only needed to contribute and for backup/restore. Moderator role
is stored in the backend and enforced by RLS.

## Infrastructure & Deployment

- **Mobile:** Android APK/AAB (app ID `com.zemaapp.zema`); iOS later.
- **Backend:** Supabase project; schema as migrations in `backend/`, plus a seed script.
- **Admin website:** Flutter web built to static files, deployed to Vercel or similar
  through GitHub Actions (stage 8).
- **CI:** GitHub Actions running `flutter analyze`, `flutter test`, `dart test`.

## Package Manager

**pub**, with a **Dart pub workspace** at the repo root (single shared `pubspec.lock`).
Members: `apps/mobile`, `packages/zema_core`; add `apps/admin` and `packages/zema_data`
to the root `pubspec.yaml` `workspace:` list when they are created. Run `flutter pub get`
from the root.

## Decision Relationships

- `zema_core` is pure Dart (no Flutter, no Supabase), so the mobile app, admin site and
  `dart test` can all use it. Backends plug in through repository interfaces
  (`FakeLyricsRepository` in stage 3, Supabase in stage 4).
- Ethiopic search normalization lives in `zema_core` and must be mirrored server-side
  (stage 4), so local and cloud search give the same results.
- Drift serves both the user's library and the offline lyrics cache. This is what makes
  the app work without internet.
- Detection is native because only a `NotificationListenerService` stays bound while
  Zema is closed. The overlay decision depends on whether that listener can start a
  Flutter engine reliably.
