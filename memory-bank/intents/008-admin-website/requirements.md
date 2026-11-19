---
intent: 008-admin-website
phase: construction
status: built
created: 2026-10-23T22:16:40Z
updated: 2026-11-19T10:00:00Z
---

# Requirements: Admin Website

> Source: `docs/roadmap.md` Stage 8; product owner, 2026-11-19 (browse + hide/restore,
> Cloudflare Pages, no audit log yet).

## Intent Overview

A website for moderators (`apps/admin`, Flutter web, shares `zema_core` and `zema_data`)
to review contributions and reports and to hide bad songs, so moderation no longer
happens in the Supabase table editor (which skips publishing).

## Business Goals

| Goal | Success Metric | Priority |
|------|----------------|----------|
| Moderate from a browser | A moderator approves a contribution on the site and the song shows in the app within 30 min | Must |
| No more table-editor approvals | Every approval goes through `review_contribution` | Must |

## Functional Requirements

### FR-1: Sign in with Google, moderators only
Google sign-in on the web. Users without the moderator or admin role see "Not a
moderator" and nothing else. The server enforces this (`require_moderator`).

### FR-2: Contribution queue
The pending contributions of others, oldest first (`moderator_queue`), filterable by
kind. Each one shows the submitted song next to the current one (changed lines
marked) and the timings. Approve (optional note), Request changes or Reject (note
required), via `review_contribution`.

### FR-3: Fingerprint queue (Should)
Pending library fingerprints (`moderator_fingerprints`), approve or reject
(`review_fingerprint`). Empty while uploads are paused.

### FR-4: Reports
Open reports, newest first, with song, reason and note; open the song; mark resolved
or dismissed. Needs new server functions.

### FR-5: Catalog
Search the catalog by title or artist, including hidden songs. Hide a song (it
leaves the song index, so phones drop it on their next refresh) or restore it.
Editing words stays a contribution. Needs a new server function.

### FR-6: Deployment
`apps/admin` joins the pub workspace, is built with `flutter build web` and uploaded to
Cloudflare Pages with `wrangler pages deploy`. The page's origin is added to Supabase
auth redirect URLs. Deploy on push comes after the GitHub repository exists.

## Non-Functional Requirements

| Area | Requirement |
|------|-------------|
| Security | Every moderator action is checked by the server; the site holds only the anon key |
| Layout | Desktop first, usable at ≥ 1024 px; works (stacked) on a phone |
| Look | Same theme tokens and fonts as the app |

## Constraints

- Reuse `SupabaseContributionRepository` and the models from `zema_data`/`zema_core`.
- Hosted changes (migrations, auth URLs) are applied only after the owner confirms.

## Out of Scope

Audit log, editing song text in place, granting roles from the site (stays
`backend/scripts/moderator.sh`), mobile-store style analytics.

## Open Questions

| Question | Resolution |
|----------|------------|
| Hosting | Cloudflare Pages (2026-11-19) |
| Audit log | Not yet; contributions keep reviewer and review time (2026-11-19) |
| Custom domain | Later; `*.pages.dev` for now |
