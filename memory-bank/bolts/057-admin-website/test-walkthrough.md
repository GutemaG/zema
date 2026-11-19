# Tests: 057-admin-website

- pgTAP 019: + `moderator_song` (moderators read hidden songs, not drafts; others refused). 640 tests pass.
- `zema_data/test/moderation_backend_test.dart` on the local backend: roles, reports read/resolve/bad status, hide → gone from index and `get_song`, readable by moderators, restore, unknown song.
- `apps/admin/test/moderation_pages_test.dart`, 8 widget tests: report filters, resolve, dismiss, Open song; catalog search, lyrics, hide confirm/cancel, restore, Load more.
- Totals: admin 26, zema_core 353, zema_data 75, mobile 1419, pgTAP 640; analyze clean; `flutter build web` builds.
