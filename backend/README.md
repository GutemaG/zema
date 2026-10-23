# backend

Backend configuration, kept in version control. The backend (Supabase or Firebase) is
not chosen yet.

Planned contents once chosen:

- Database schema / migrations (songs, recordings, lyric sections, sync timings,
  contributions, user backups)
- Access rules (Supabase Row Level Security or Firebase security rules), e.g. only
  moderators can approve, edit or delete lyrics
- Server functions (e.g. search indexing, moderation actions)
- Seed lyrics catalog
