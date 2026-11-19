# Implementation: 057-admin-website

- `packages/zema_core/lib/src/moderation/moderation.dart`; `packages/zema_data/lib/src/supabase_moderation_repository.dart` (the catalog repository now uses the shared `reportReasonWire`).
- `backend/supabase/migrations/20261119000100_moderation.sql`: `moderator_song`.
- `apps/admin/lib/src/reports_page.dart`, `catalog_page.dart`; `moderationRepositoryProvider` in `session.dart`.
