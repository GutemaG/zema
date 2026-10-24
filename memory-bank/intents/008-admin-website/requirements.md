---
intent: 008-admin-website
phase: inception
status: draft
created: 2026-10-23T22:16:40Z
updated: 2026-10-23T22:16:40Z
---

# Requirements: Admin Website

> Source: `docs/roadmap.md` Stage 8 · Complexity ★★★☆☆ · Needs backend.

## Intent Overview

A web dashboard for moderators (`apps/admin`, Flutter web, shares `zema_core`) to review
submissions and manage the catalog, deployed as static files.

## Business Goals

| Goal | Success Metric | Priority |
|------|----------------|----------|
| Efficient moderation | A moderator approves a submission on the website and it appears in the app | Must |

---

## Functional Requirements

### FR-1: Google sign-in with moderator role
- **Description**: Sign in with Google; access requires moderator role enforced by backend rules.
- **Priority**: Must

### FR-2: Review queue
- **Description**: Pending submissions with side-by-side diff (submitted vs current) and sync preview; Approve / Request changes (comment) / Reject (reason).
- **Priority**: Must

### FR-3: Catalog management
- **Description**: Browse, search, edit, unpublish songs and recordings.
- **Priority**: Must

### FR-4: Wrong-lyrics reports
- **Description**: List and resolve reports from 004.
- **Priority**: Must

### FR-5: Deployment
- **Description**: `apps/admin` added to pub workspace; built as static files; deployed (Vercel or similar) via GitHub Actions.
- **Priority**: Must

---

## Non-Functional Requirements

### Security
| Requirement | Standard | Notes |
|-------------|----------|-------|
| Authorization | Supabase RLS | All moderator actions enforced server-side, not by the website |

### Usability
| Requirement | Metric | Target |
|-------------|--------|--------|
| Layout | Desktop browser | Wide layouts; usable at ≥ 1024 px |

---

## Constraints

### Technical Constraints

**Project-wide standards**: Required standards will be loaded from memory-bank standards folder by Construction Agent

**Intent-specific constraints**:
- Reuse `zema_core` (models, validation, normalization) and `zema_data`.
- Same design tokens as the app (dark palettes).

### Business Constraints
- Depends on 004 (backend) and 006 (contributions, moderator role).

---

## Assumptions

| Assumption | Risk if Invalid | Mitigation |
|------------|-----------------|------------|
| Flutter web is good enough for a data-heavy admin UI | Poor UX/perf | Keep views simple; paginate |

---

## Open Questions

| Question | Owner | Due Date | Resolution |
|----------|-------|----------|------------|
| Hosting provider (Vercel or similar) | Product owner | Before deployment bolt | Pending |
| Audit log of moderator actions needed? | Product owner | Requirements review | Pending |
