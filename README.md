# Zema

Music player and synchronized-lyrics companion for Ethiopian Orthodox Tewahedo mezmur.
Plays local files, detects songs playing in YouTube / Telegram, and shows synced lyrics
in a floating window. Community-contributed lyrics with moderation; Google sign-in for
contributing and backup/restore.

## Repository layout

```
apps/
  mobile/            Flutter app (Android/iOS); native Kotlin in android/app/src/main/kotlin
  admin/             admin website for moderators (planned, Flutter web)
packages/
  zema_core/         shared pure-Dart domain logic: models, lyrics, search, matching,
                     repository interfaces
backend/             schema, access rules, functions, seed data (backend not chosen yet)
docs/                roadmap.md (specsmd start), screens.md, design-system.md,
                     flutter-build-notes.md
design/              screen images (design/screens/) and design canvas source
pubspec.yaml         Dart pub workspace root (single shared lockfile)
```

## Getting started

```
flutter pub get          # from the repo root; resolves all workspace members
cd apps/mobile && flutter run
```

## Reference

The earlier Kotlin app, [LyricFlow](https://github.com/GutemaG/LyricFlow), is used as a
reference only.
