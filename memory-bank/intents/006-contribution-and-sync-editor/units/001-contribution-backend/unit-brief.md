---
unit: 001-contribution-backend
intent: 006-contribution-and-sync-editor
unit_type: backend
default_bolt_type: simple-construction-bolt
phase: inception
status: complete
created: '2026-11-02T07:00:52Z'
updated: '2026-11-02T07:00:52Z'
---

# Unit Brief: Contribution Backend

## Purpose

Lets signed-in users submit contributions and moderators review them. Approving a
contribution publishes it into the catalog. All of it is enforced by RLS and server
functions, and proven with pgTAP against the local Supabase.

## Scope

### In Scope
- `submit_contribution` and `resubmit_contribution` RPCs. They check the shared rules,
  limits of 20 pending, 30 a day and 256 KB, and a new `recording` kind.
- Users read only their own contributions. No direct writes.
- `moderator_queue` and `review_contribution`, for moderators only. No self-review,
  required notes, and row locks so racing reviews leave one result.
- Publishing on approval in one transaction:
  - new song, edit lyrics (the version bumps and timings that no longer fit are
    removed), recording, and sync timing
  - recordings get `youtube_id` and `file_name` columns, and `get_song` returns them
- `backend/scripts/moderator.sh grant|revoke <email>`, with `docs/moderators.md`

### Out of Scope
- Admin website and role screens (008)
- Push notifications
- Audio storage

---

## Assigned Requirements

| FR | Requirement | Priority |
|----|-------------|----------|
| FR-8 | Corrections (publishing and the timing rule) | Must |
| FR-9 | My contributions (own rows readable) | Must |
| FR-10 | Moderator queue (server side) | Must |
| FR-11 | Shared validation (server check) | Must |
| FR-13 | Server contributions, moderation and publishing | Must |

---

## Story Summary

| Metric | Count |
|--------|-------|
| Total Stories | 3 |
| Must Have | 3 |
| Should Have | 0 |
| Could Have | 0 |

### Stories

| Story ID | Title | Priority | Status |
|----------|-------|----------|--------|
| 001-submit-contributions | Submit and resubmit contributions | Must | Planned |
| 002-review-and-moderator-role | Review RPC and the moderator role | Must | Planned |
| 003-publish-on-approval | Publish approved contributions | Must | Planned |

---

## Dependencies

### Depends On
| Unit | Reason |
|------|--------|
| 004 `001-cloud-lyrics-catalog-backend` | Catalog tables, `contributions`, `seed_song`, `get_song`, version bumps |
| 005 `001-accounts-backend` | Profiles, `user_roles`, sign-in |

### Depended By
| Unit | Reason |
|------|--------|
| 002-contribution-and-sync-editor-ui | Submit, list, review |
| Intent 008 | Moderation on the web |

---

## Technical Context

### Suggested Technology
Supabase CLI via `npx supabase` (Docker), Postgres and pgTAP. Test users are created in
rolled-back transactions and impersonated with `request.jwt.claims`, as in 005. The RPCs
are `security definer` with `search_path = ''`.

### Data Storage
| Data | Type | Volume | Retention |
|------|------|--------|-----------|
| Contributions | Postgres `jsonb` payload | ≤ 256 KB each; ≤ 20 pending per user | Kept after review, for history |
| Published content | Existing catalog tables | Per approval | Until changed by a later approval |

---

## Constraints

- Nothing pending is readable by `anon` or by other users.
- No service key is committed. The script reads it from the environment.
- The rules match `zema_core`'s validation, and the error codes are shared.

---

## Success Criteria

### Functional
- [ ] `supabase db reset` and `supabase test db` pass
- [ ] Submit and resubmit rules, limits and RLS work
- [ ] Only moderators review; no self-review; races leave one result
- [ ] Each kind publishes correctly, and nothing is public before approval

### Non-Functional
- [ ] Approval is all or nothing
- [ ] Key scan clean; no secrets in the repo
