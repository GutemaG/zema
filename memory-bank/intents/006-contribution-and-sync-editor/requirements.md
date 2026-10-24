---
intent: 006-contribution-and-sync-editor
phase: inception
status: draft
created: 2026-10-23T22:16:40Z
updated: 2026-10-23T22:16:40Z
---

# Requirements: Contribution and Sync Editor

> Source: `docs/roadmap.md` Stage 6 · screens: `docs/screens.md` S07, S09, S19–S23, S23m ·
> design variants 7a–7d: `docs/design-system.md` · Complexity ★★★★☆ · Needs backend; small
> native piece (Android share intent).

## Intent Overview

Signed-in users add lyrics, link recordings and sync timings; moderators approve,
request changes or reject; approved content becomes public.

## Business Goals

| Goal | Success Metric | Priority |
|------|----------------|----------|
| Community-grown catalog | User submits lyrics + sync for a local song; moderator approves; another device sees synced lyrics | Must |
| Quality control | No content public without moderator approval | Must |

---

## Functional Requirements

### FR-1: Add lyrics (S19, step 1/4)
- **Description**: Title, transliteration, artist, album; duplicate check while typing; block editor (Verse/Chorus/Bridge + lines, add/delete/reorder); play-order strip; "Paste all text" auto-split; autosaved local draft.
- **Priority**: Must

### FR-2: Link recording (S20, step 2/4)
- **Description**: YouTube link → video ID, title, thumbnail, duration; Telegram audio via Android share intent; local file from library; artist/choir name. Also reachable from S07 "Link a recording".
- **Priority**: Must

### FR-3: Sync editor (S21, step 3/4)
- **Description**: Variant chosen from 7a–7d. Plays recording; tap records time for highlighted line; undo, rewind 5 s, speed 0.75×/1×, nudge a timestamp; each chorus repeat timed separately; preview mode; optional (text-only submit allowed).
- **Priority**: Must

### FR-4: Review & submit (S22, step 4/4)
- **Description**: Summary; submit → Pending contribution; local copy visible immediately; link to S23.
- **Priority**: Must

### FR-5: My contributions (S23)
- **Description**: Tabs Pending / Approved / Needs changes / Rejected; card with type, date, moderator comment; "Edit" reopens flow for Needs changes.
- **Priority**: Must

### FR-6: Moderator review queue in app (S23m)
- **Description**: Moderator-only; oldest first, filter by type; diff vs current lyrics; sync preview; checklist; Approve / Request changes (comment required) / Reject (reason required).
- **Priority**: Must

### FR-7: Edit song info (S09)
- **Description**: Edit title, artist, album, track number, art for local files; stored in Zema DB (file untouched); used for matching.
- **Priority**: Should

### FR-8: Shared validation (`zema_core`)
- **Description**: Title required, ≥1 section, timestamps strictly increasing.
- **Priority**: Must

### FR-9: Moderator role and approval in backend
- **Description**: Role stored server-side; RLS lets only moderators change status; approved content becomes publicly readable.
- **Priority**: Must

---

## Non-Functional Requirements

### Security
| Requirement | Standard | Notes |
|-------------|----------|-------|
| Authorization | RLS | Contributors write own pending items only; moderators approve |

### Usability
| Requirement | Metric | Target |
|-------------|--------|--------|
| Sync accuracy from tap editor | Typical offset after nudge | ≤ ±0.3 s |
| Draft safety | Data lost on app kill | None |

---

## Constraints

### Technical Constraints

**Project-wide standards**: Required standards will be loaded from memory-bank standards folder by Construction Agent

**Intent-specific constraints**:
- Requires sign-in (005). Contribute tab shows C09 for guests.
- YouTube metadata fetch must not require playing video in-app (video playback is out of product scope).

### Business Constraints
- Admin website comes in 008; until then moderation happens in-app.

---

## Assumptions

| Assumption | Risk if Invalid | Mitigation |
|------------|-----------------|------------|
| YouTube oEmbed/metadata is enough to get title/duration | Missing duration | Ask user or derive from detection later |
| Telegram allows sharing audio files to other apps | Can't link Telegram recordings | Fall back to "save to device then pick local file" |

---

## Open Questions

| Question | Owner | Due Date | Resolution |
|----------|-------|----------|------------|
| **Sync editor variant: 7a list / 7b focus / 7c tap the line / 7d "we guess, you check"** (roadmap open decision #1) | Product owner | Before this intent's requirements | Pending |
| **How are moderators chosen?** (roadmap open decision #4) | Product owner | Before this intent's requirements | Pending |
| Syncing against a YouTube recording: how does the user hear it without in-app video? | Product owner | Requirements review | Pending |
