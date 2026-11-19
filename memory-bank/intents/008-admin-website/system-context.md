# System Context: Admin Website

```
Moderator ── browser ── apps/admin (Cloudflare Pages, static)
                            │  anon key + moderator's session
                            ▼
                     Supabase (hosted)
                     ├─ auth: Google provider, redirect to the Pages URL
                     ├─ RPC: moderator_queue, review_contribution,
                     │       moderator_fingerprints, review_fingerprint   (exist)
                     ├─ RPC: moderator_reports, resolve_report,
                     │       moderator_songs, set_song_hidden              (new)
                     └─ song_index ──► phones (drop hidden songs on refresh)
Owner ── backend/scripts/moderator.sh ── set_moderator (service key)
```

- **In**: the moderator's Google account, contributions and reports sent from phones.
- **Out**: published or hidden songs, reviewed contributions (authors see the note in
  My contributions), resolved reports.
