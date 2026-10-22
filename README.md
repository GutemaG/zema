# Zema

Music player and synchronized-lyrics companion for Ethiopian Orthodox Tewahedo mezmur.
Plays local files, detects songs playing in YouTube / Telegram, and shows synced lyrics
in a floating window. Community-contributed lyrics with moderation; sign-in for
contributing and backup/restore.

## Layout

- `lib/` — Flutter (Dart) app code
- `android/app/src/main/kotlin/` — native Android code (playback detection, overlay)
- `docs/zema-stitch-prompts.md` — Google Stitch prompts and Flutter build notes
- `design/stitch/` — exported Stitch designs (HTML / screenshots) used as UI reference

## Reference

The earlier Kotlin app, [LyricFlow](https://github.com/GutemaG/LyricFlow), is used as a
reference only.
