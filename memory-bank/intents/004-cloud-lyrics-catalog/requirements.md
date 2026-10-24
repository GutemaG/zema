---
intent: 004-cloud-lyrics-catalog
phase: inception
status: draft
created: 2026-10-23T22:16:40Z
updated: 2026-10-23T22:16:40Z
---

# Requirements: Cloud Lyrics Catalog

> Source: `docs/roadmap.md` Stage 4 · screens: `docs/screens.md` S05, S07 (Recordings),
> S28 · Complexity ★★★☆☆ · Needs backend (Supabase).

## Intent Overview

Replace sample data with the shared online lyrics catalog (read-only), while keeping the
app fully usable offline through a local cache.

## Business Goals

| Goal | Success Metric | Priority |
|------|----------------|----------|
| Real catalog in the app | Lyrics for a matched song load from the backend | Must |
| Offline-first | Same lyrics show later with no internet | Must |
| Fast search on slow networks | Cloud results < 1 s on 3G-class connections | Must |

---

## Functional Requirements

### FR-1: Backend schema (`backend/`)
- **Description**: Migrations for songs, sections, play order, recordings, sync timings, contributions, users/roles, reports.
- **Priority**: Must

### FR-2: Row Level Security
- **Description**: Public read of approved content only; no anonymous writes (except reports, see FR-7).
- **Acceptance Criteria**: RLS tests prove unapproved content is not readable.
- **Priority**: Must

### FR-3: Server-side search
- **Description**: Search RPC using the same normalization rules as `zema_core`.
- **Acceptance Criteria**: Same queries from 003 tests return the same songs server-side.
- **Priority**: Must

### FR-4: Seed script
- **Description**: Load the initial catalog into the backend.
- **Priority**: Must

### FR-5: `packages/zema_data` Supabase repository
- **Description**: Supabase implementation of `LyricsRepository`; add package to the pub workspace.
- **Priority**: Must

### FR-6: Offline cache
- **Description**: Fetched lyrics cached in Drift; served when offline; optional "Download all lyrics for offline" and storage used in S28.
- **Priority**: Must (cache) / Should (download all)

### FR-7: Report wrong lyrics
- **Description**: From S07/S08; stored as a report for moderators.
- **Priority**: Should

### FR-8: Song detail — Recordings tab (read-only)
- **Description**: Versions by artist with source, duration, sync status.
- **Priority**: Should

### FR-9: Home — "New lyrics from the community"
- **Description**: Recently approved lyrics with Synced / Text-only badge.
- **Priority**: Could

### FR-10: Search merges local + cloud
- **Description**: S06 shows cloud results when online, local always; C07 offline state for cloud section.
- **Priority**: Must

---

## Non-Functional Requirements

### Performance
| Requirement | Metric | Target |
|-------------|--------|--------|
| Cloud search | Response on 3G-class network | < 1 s |

### Security
| Requirement | Standard | Notes |
|-------------|----------|-------|
| Authorization | Supabase RLS | All rules server-side |

### Reliability
| Requirement | Metric | Target |
|-------------|--------|--------|
| Offline | Cached lyrics availability | 100% of previously viewed songs |

---

## Constraints

### Technical Constraints

**Project-wide standards**: Required standards will be loaded from memory-bank standards folder by Construction Agent

**Intent-specific constraints**:
- Introduces the first backend; schema must already support contributions and roles (used in 005/006) even if not written to yet.

### Business Constraints
- **Out of scope:** sign-in, writing data (except reports).

---

## Assumptions

| Assumption | Risk if Invalid | Mitigation |
|------------|-----------------|------------|
| Supabase free/low tier is enough initially | Cost/limits | Monitor usage; cache aggressively |
| Anonymous reports are acceptable | Spam | Rate limit; revisit when sign-in exists |

---

## Open Questions

| Question | Owner | Due Date | Resolution |
|----------|-------|----------|------------|
| **How is the first lyrics catalog seeded?** (roadmap open decision #3) | Product owner | Before this intent's requirements | Pending |
| Can guests submit "wrong lyrics" reports, or sign-in only? | Product owner | Requirements review | Pending |
