# Plan: 054-moderation-backend

- New `hidden` value of `song_status`, in its own migration (an enum value can't be used in the transaction that adds it).
- `moderator_reports`, `resolve_report`, `moderator_songs`, `set_song_hidden`: security definer, `require_moderator` first, granted to `authenticated` only.
- Nothing else changes: everything listeners read already keeps to `status = 'approved'`.
