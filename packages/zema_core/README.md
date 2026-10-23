# zema_core

Shared, pure-Dart domain logic for Zema, used by `apps/mobile`, `apps/admin` and tooling.

Planned contents:

- **Models** — Song, Recording, LyricSection, SyncTiming, Contribution
- **Lyrics** — play order expansion, "paste all text" block splitting
- **Sync** — current line for a playback position and sync offset
- **Search normalization** — Ethiopic letter variants, transliteration, title cleanup
- **Matching** — detected title → best song match with confidence
- **Validation** — rules for submissions
- **Repository interfaces** — implemented by `packages/zema_data` (backend) and fakes

Rule: no Flutter and no backend imports in this package.
