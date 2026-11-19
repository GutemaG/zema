---
intent: 008-admin-website
created: 2026-10-23T22:16:40Z
completed: 2026-11-19T10:00:00Z
status: complete
---

# Inception Log: 008-admin-website

| Artifact | File |
|----------|------|
| Requirements (6 FR) | requirements.md |
| System context | system-context.md |
| Units (2), stories (7) | units.md, units/ |
| Bolts | 054-moderation-backend, 055–057-admin-website |

## Decision Log

| Date | Decision | Rationale |
|------|----------|-----------|
| 2026-10-23 | Draft from roadmap stage 8 | All stages drafted up front |
| 2026-11-19 | Catalog: browse + hide/restore; text edits stay contributions | Keeps the site small; one new RPC |
| 2026-11-19 | Cloudflare Pages, manual `wrangler` deploy until the GitHub repo exists | Owner's choice |
| 2026-11-19 | No audit log yet | Contributions already keep reviewer and time |
| 2026-11-19 | Hidden songs use a new `hidden` song status | Phones already drop songs missing from the index |

| 2026-11-19 | Web sign-in through Supabase's Google redirect (PKCE), added to `SupabaseAuthRepository` | Reuses every zema_data repository |
| 2026-11-19 | `moderator_song` RPC added in bolt 057 | `get_song` serves approved songs only |

## Status

Bolts 054–057 built and tested locally. Left for the owner: the migration on hosted (`npx supabase db push`), the one-time setup in `docs/admin-website.md`, then `apps/admin/tool/deploy.sh`.
