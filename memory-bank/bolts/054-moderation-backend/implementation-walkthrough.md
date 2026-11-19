# Implementation: 054-moderation-backend

- `20261119000000_hidden_songs.sql`: adds `hidden`.
- `20261119000100_moderation.sql`: the four RPCs; `songs_before_update` keeps `approved_at` when a hidden song is restored.
- Reports are returned without the install hash; lists are paged (reports ≤ 500, songs ≤ 200 a page).
- Approving a pending edit of a hidden song already fails with `unknown_song` (`publish_contribution` re-runs `check_contribution`).
- Not applied to hosted yet: needs `npx supabase db push` after the owner confirms.
