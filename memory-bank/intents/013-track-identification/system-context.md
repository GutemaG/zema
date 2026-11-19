# System Context: Identify Badly Tagged Tracks

```
Phone (library file, no link)
  1. clean tags → SongMatcher ───────────────► linked by title ──┐
  2. TrackPrinter (first 120 s) ── match_track ─► linked by print │
  3. user links by hand ──────────────────────────────────────────┤
                                                                   ▼
                           share_track_print (consent) ──► Supabase
                                                            ├─ track_prints (pending/published)
                                                            ├─ match_track (rate-limited)
Seed tool, contributions ──────────────────────────────────►├─ second install agrees → published
Moderator ── admin site Fingerprints page ─────────────────►└─ review_track_print
```

- **In**: prints of users' files (never audio), the owner's seed prints.
- **Out**: song links on phones.
