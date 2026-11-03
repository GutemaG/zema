---
id: 053-contribution-and-sync-editor-ui
unit: 002-contribution-and-sync-editor-ui
intent: 006-contribution-and-sync-editor
type: simple-construction-bolt
status: complete
stories:
  - 016-local-lyrics-without-account
created: '2026-11-03T09:00:00Z'
started: '2026-11-03T09:00:00Z'
completed: '2026-11-03T06:07:54Z'
current_stage: null
stages_completed:
  - name: plan
    completed: '2026-11-03T09:05:00Z'
    artifact: bolt.md
  - name: implement
    completed: '2026-11-03T09:40:00Z'
    artifact: bolt.md
  - name: test
    completed: '2026-11-03T10:00:00Z'
    artifact: bolt.md
requires_bolts:
  - 052-contribution-and-sync-editor-ui
enables_bolts: []
requires_units: []
blocks: false
complexity:
  avg_complexity: 2
  avg_uncertainty: 1
  max_dependencies: 1
  testing_scope: 2
---

# Bolt: 053-contribution-and-sync-editor-ui

## Overview

Change request: lyrics without an account. Guests add lyrics and keep them on the phone; only sending for review needs sign-in.

## Notes

- No sign-in gate when starting (startContribution, shared files). S05 lists drafts for everyone; My contributions stays signed-in only.
- S22: Save on this phone (asks which song on the phone when the draft has none, e.g. lyrics without a recording) stores an own copy `local-<draftId>`; the player shows it with an "On this phone" chip, and Lyrics options offers "Edit or send these lyrics" (no Report). Submit asks a guest to sign in (C09) first.
- Sending or deleting the draft removes its saved copy. Sign-out and delete account keep drafts and saved lyrics (the drafts warning on Profile is gone); sent copies still go.
- No schema or core change. Saved lyrics aren't in the backup yet.
- Skip on S20 keeps the draft's song (it used to drop it, so lyrics started from a song lost it).
- App tests 1,221 pass; 5 of 5 planted bugs caught.
