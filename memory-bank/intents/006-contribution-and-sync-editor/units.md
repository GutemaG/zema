---
intent: 006-contribution-and-sync-editor
phase: inception
status: units-decomposed
updated: 2026-11-02T07:00:52Z
---

# Contribution and Sync Editor - Unit Decomposition

## Units Overview

As in 004 and 005, the intent splits into **2 units**:

- **A backend unit**: the contribution and review functions, policies, limits,
  publishing on approval, and the moderator script, built and tested with pgTAP against
  the local Supabase.
- **The app unit**: `zema_core` and `zema_data` code, the four-step flow, the sync
  editor, My contributions, the moderator queue, and S09.

Both use the simple construction bolt. The backend comes first, so the app can submit
to and review against the real local server from its first repository bolt.

### Unit 1: 001-contribution-backend

**Description**:

- Submit and resubmit RPCs that check the shared rules and the limits, and read
  policies for a user's own contributions.
- A review RPC for moderators only, with no self-review and safe races, plus the
  moderator queue read and the owner's moderator script.
- Publishing on approval for each kind, in one transaction, with source reference
  columns on `recordings`.

**Stories**:

- 001-submit-contributions
- 002-review-and-moderator-role
- 003-publish-on-approval

**Deliverables**:

- `backend/supabase/migrations/` (contribution RPCs, policies, limits, publishing,
  recording source columns)
- `backend/supabase/tests/database/` (pgTAP)
- `backend/scripts/` (moderator grant/revoke script) and its usage in `docs/`

**Dependencies**:

- Depends on: intents 004 (catalog, `contributions`, `seed_song`) and 005 (profiles,
  `user_roles`)
- Depended by: `002-contribution-and-sync-editor-ui`; intent 008

**Estimated Complexity**: M

### Unit 2: 002-contribution-and-sync-editor-ui

**Description**:

- **Model and data**: the contribution draft and payload, the validation rules,
  paste-split, line occurrences and YouTube ID parsing in `zema_core`; the
  contribution repository in `zema_data`, with a fake for tests.
- **The flow**:
  - S05 with drafts and the C09 gate
  - S19 block editor and play order
  - S20 local, YouTube and Telegram recordings
  - S21 sync editor, List and Focus views, and preview
  - S22 submit, and the contributor's own copy
- **Around it**: the duplicate check and entry points, corrections, S23 with the badge,
  S23m, S09, and the backup additions.

**Stories**:

- 001-contribution-model-and-validation
- 002-contribution-repository
- 003-contribute-tab-and-drafts
- 004-add-lyrics-editor
- 005-link-recording
- 006-telegram-share
- 007-sync-editor-list
- 008-sync-editor-focus-and-preview
- 009-review-and-submit
- 010-duplicate-check-and-entry-points
- 011-corrections
- 012-my-contributions-and-badge
- 013-moderator-queue
- 014-edit-song-info
- 015-backup-additions

**Deliverables**:

- `packages/zema_core` (contribution model, validation, paste-split, repository
  interface)
- `packages/zema_data` (Supabase contribution repository)
- `apps/mobile/lib/features/contribute/`: S05, S19–S23, S23m
- S09 in the library and lyrics features
- Drift schema v8+ (drafts, own copies, overrides); the Android share intent
- ARB strings in the four languages
- Unit, Drift, widget and emulator checks against the local backend

**Dependencies**:

- Depends on: `001-contribution-backend`, intents 001–005
- Depended by: intents 007 (sync timings for detection), 008 (admin moderation)

**Estimated Complexity**: L

## Requirement-to-Unit Mapping

- **FR-1** Contribute tab and entry points → ui (003, 010)
- **FR-2** Add lyrics (S19) → ui (004, 010)
- **FR-3** Link recording (S20) → ui (005, 006)
- **FR-4** Sync editor (S21) → ui (007, 008)
- **FR-5** Review & submit (S22) → ui (009)
- **FR-6** Drafts → ui (003)
- **FR-7** The contributor's own copy → ui (009)
- **FR-8** Corrections → backend (003); ui (011)
- **FR-9** My contributions and badge → backend (001); ui (012)
- **FR-10** Moderator queue (S23m) → backend (002); ui (013)
- **FR-11** Shared validation → backend (001); ui (001)
- **FR-12** Edit song info (S09) → ui (014)
- **FR-13** Server contributions, moderation, publishing → backend (001, 002, 003); ui (002)
- **FR-14** Backup additions → ui (015)

## Unit Dependency Graph

```text
[004 catalog backend, 005 accounts backend] (complete)
     │
     ▼
[001-contribution-backend]
     │
     ▼
[002-contribution-and-sync-editor-ui]
```

## Execution Order

Bolts have 1–2 stories each, so each finishes in one session:

1. Bolt 039: submit and resubmit, policies, limits (backend 001)
2. Bolt 040: review RPC, moderator queue read, moderator script (backend 002)
3. Bolt 041: publishing on approval (backend 003)
4. Bolt 042: contribution model and validation, repository (ui 001–002)
5. Bolt 043: Contribute tab S05 and drafts (ui 003)
6. Bolt 044: Add lyrics S19 (ui 004)
7. Bolt 045: Link recording S20 and Telegram share (ui 005–006)
8. Bolt 046: sync editor, List view (ui 007)
9. Bolt 047: sync editor, Focus view and preview (ui 008)
10. Bolt 048: Review & submit S22 and the own copy (ui 009)
11. Bolt 049: duplicate check, entry points, corrections (ui 010–011)
12. Bolt 050: My contributions S23 and the badge (ui 012)
13. Bolt 051: moderator queue S23m and the intent's end-to-end check (ui 013)
14. Bolt 052: Edit song info S09 and backup additions (ui 014–015)
