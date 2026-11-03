---
id: 016-local-lyrics-without-account
unit: 002-contribution-and-sync-editor-ui
intent: 006-contribution-and-sync-editor
status: complete
priority: must
created: '2026-11-03T09:00:00Z'
assigned_bolt: 053-contribution-and-sync-editor-ui
implemented: true
---

# Story: 016-local-lyrics-without-account

## User Story

**As a** user without an account
**I want** to add lyrics and timings for songs on my phone and keep them there
**So that** I can sing along without signing in, and sign in only to share them

## Acceptance Criteria

- [x] **Given** a guest, **When** they start lyrics from any entry point or share a file, **Then** a draft opens with no sign-in prompt, and S05 lists their drafts
- [x] **Given** a draft, **When** Save on this phone is tapped (choosing the song on the phone if the draft has none), **Then** the track shows the lyrics (synced when timed), marked "On this phone"; the draft stays, to edit or send later
- [x] **Given** a guest on S22, **When** Submit for review is tapped, **Then** C09 asks them to sign in, and the draft is sent only after they do
- [x] **Given** saved lyrics, **When** the draft is sent or deleted, **Then** the saved copy goes
- [x] **Given** sign-out or account deletion, **When** it runs, **Then** drafts and saved lyrics stay; only copies of sent contributions go

## Technical Notes

- A saved copy is an own copy with id `local-<draftId>`; reconcile never matches it.
