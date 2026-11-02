---
unit: 002-contribution-and-sync-editor-ui
intent: 006-contribution-and-sync-editor
unit_type: frontend
default_bolt_type: simple-construction-bolt
phase: inception
status: stories-defined
created: '2026-11-02T07:00:52Z'
updated: '2026-11-02T07:00:52Z'
---

# Unit Brief: Contribution and Sync Editor UI

## Purpose

The contributor's and moderator's side of the app:

- the four-step flow: lyrics, recording, sync and submit
- drafts
- following a contribution's status
- reviewing in the app
- editing a local file's song info

## Scope

### In Scope
- **`zema_core`**: the contribution draft and payload (004's song document format),
  the validation rules, `splitPastedLyrics`, YouTube ID parsing, and the
  `ContributionRepository` interface.
- **`zema_data`**: the Supabase contribution repository, with a fake for tests.
- **S05**: Contribute tab, with the C09 gate and drafts.
- **S19**: Add lyrics, with the block editor and play order.
- **S20**: Link recording from a local file, YouTube (oEmbed), or Telegram share on
  Android.
- **S21**: sync editor, List (7a) and Focus (7b) views, Preview. No counters.
- **S22**: submit, and the contributor's own pending copy.
- **Duplicate check and entry points**: search, a track without lyrics, Song detail.
- **Corrections** to approved songs.
- **S23**: My contributions, the in-app status badge, and the Profile stats.
- **S23m**: moderator queue.
- **S09**: Edit song info, stored as overrides.
- **Backup additions**: overrides and sync offsets.

### Out of Scope
- Push notifications, YouTube sync, in-app video, iOS share target, audio upload

---

## Assigned Requirements

| FR | Requirement | Priority |
|----|-------------|----------|
| FR-1 | Contribute tab and entry points | Must |
| FR-2 | Add lyrics (S19) | Must |
| FR-3 | Link recording (S20) | Must (Telegram: Should) |
| FR-4 | Sync editor (S21) | Must |
| FR-5 | Review & submit (S22) | Must |
| FR-6 | Drafts | Must |
| FR-7 | The contributor's own copy | Must |
| FR-8 | Corrections | Must |
| FR-9 | My contributions and badge | Must |
| FR-10 | Moderator queue (S23m) | Must |
| FR-11 | Shared validation | Must |
| FR-12 | Edit song info (S09) | Should |
| FR-13 | Server contributions (client) | Must |
| FR-14 | Backup additions | Could |

---

## Story Summary

| Metric | Count |
|--------|-------|
| Total Stories | 15 |
| Must Have | 12 |
| Should Have | 2 |
| Could Have | 1 |

### Stories

| Story ID | Title | Priority | Status |
|----------|-------|----------|--------|
| 001-contribution-model-and-validation | Contribution model and shared validation | Must | Planned |
| 002-contribution-repository | Contribution repository | Must | Planned |
| 003-contribute-tab-and-drafts | Contribute tab (S05) and drafts | Must | Planned |
| 004-add-lyrics-editor | Add lyrics (S19) | Must | Planned |
| 005-link-recording | Link recording (S20): local file and YouTube | Must | Planned |
| 006-telegram-share | Share audio from Telegram (Android) | Should | Planned |
| 007-sync-editor-list | Sync editor: List view (S21) | Must | Planned |
| 008-sync-editor-focus-and-preview | Sync editor: Focus view and Preview | Must | Planned |
| 009-review-and-submit | Review & submit (S22) and the own copy | Must | Planned |
| 010-duplicate-check-and-entry-points | Duplicate check and entry points | Must | Planned |
| 011-corrections | Suggest a correction | Must | Planned |
| 012-my-contributions-and-badge | My contributions (S23) and the status badge | Must | Planned |
| 013-moderator-queue | Moderator review queue (S23m) | Must | Planned |
| 014-edit-song-info | Edit song info (S09) | Should | Planned |
| 015-backup-additions | Backup additions: overrides and sync offsets | Could | Planned |

---

## Dependencies

### Depends On
| Unit | Reason |
|------|--------|
| 001-contribution-backend | Submit, review, publish |
| Intents 001–005 | Shell, library, player, lyrics view, catalog, sign-in, C09, backup |

### Depended By
| Unit | Reason |
|------|--------|
| Intent 007 | Synced lyrics for detected playback |
| Intent 008 | Same contribution model on the web |

---

## Technical Context

### Suggested Technology
- Riverpod, go_router, Drift (schema v8 and later), just_audio (a second instance for
  S21), and `http` for oEmbed.
- `receive_sharing_intent` or `share_handler` for the share intent.
- Tests with in-memory Drift, widget tests with `pumpZemaApp`, `zema_data` integration
  tests, and planted-bug runs, as in 005.

### Data Storage
| Data | Type | Volume | Retention |
|------|------|--------|-----------|
| Drafts | Drift (JSON draft + step) | A few per user | Until submitted or deleted; warned on sign-out |
| Own pending copies | Drift | One per pending contribution | Until approved or rejected |
| Song info overrides | Drift | Per edited track | Until reset |
| Copied Telegram audio | App storage | Per draft | Removed with the draft or after review |

---

## Constraints

- Only the anon key in the app. No audio upload, no in-app video.
- S21 shows no step or line counters, and Focus has no progress segments.
- Every new screen fits a small phone at 1.3× text, in dark and light. Strings go in
  all four languages.

---

## Success Criteria

### Functional
- [ ] A local song's lyrics and sync are submitted, approved in S23m, and seen on a
  wiped install with the same file
- [ ] Drafts survive the app being killed
- [ ] Status changes show as a badge and a message

### Non-Functional
- [ ] Taps recorded within 50 ms of the audio position; ±0.3 s after nudging
- [ ] Analyze and format clean, and all tests pass
