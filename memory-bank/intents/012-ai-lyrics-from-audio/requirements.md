---
intent: 012-ai-lyrics-from-audio
phase: inception
status: draft
created: 2026-10-29T15:56:27Z
updated: 2026-10-29T15:56:27Z
---

# Requirements: AI Lyrics from Audio

> Source: product owner request, 2026-10-29 (send a song's audio to a speech-to-text
> API and get draft lyrics) · Complexity ★★★★ · Needs a backend function (004) ·
> Feeds 006 (contribution and sync editor) · **Provider chosen later, by a spike.**

## Intent Overview

When a song has no lyrics, the user can ask Zema to write a first draft from the audio.
The audio of a song in their library goes, with their consent, to a speech-to-text
service through Zema's backend, and the text that comes back (with timings when the
service gives them) opens as a draft in the contribution editor. A person always checks
and corrects it before it is submitted; nothing generated goes into the catalog by
itself.

## Business Goals

| Goal | Success Metric | Priority |
|------|----------------|----------|
| Faster contributions | Writing lyrics for a 5-minute mezmur with a draft takes less than half the time it takes without | Must |
| Useful drafts | On the spike's test set, most lines need only small corrections (target set by the spike, as a word error rate) | Must |
| Draft timing | When word timings are returned, the draft also seeds the sync timing in the editor | Should |
| Affordable | Cost per song known and capped per user per day | Must |

---

## Functional Requirements

### FR-0: Spike (choose the provider)
- **Description**: Run the same set of real mezmur recordings (Amharic, Afaan Oromoo,
  Tigrinya, Ge'ez; choir and solo) through the candidate services and an on-phone
  model. Measure the word error rate, Ethiopic script output, word timings, cost per
  minute, limits and data-use terms. Also try separating the vocals from the music
  first, since sung words over instruments are much harder than speech.
- **Acceptance Criteria**: A provider (or "none good enough yet") is chosen, with the
  results recorded.
- **Priority**: Must

### FR-1: Ask for a draft
- **Description**: On a library track with no lyrics ("No lyrics yet" in Song detail or
  Now Playing), "Write lyrics with AI" explains what happens (the audio is sent to a
  named service, then deleted) and asks for consent. The user can pick the language and
  trim the part to send.
- **Priority**: Must

### FR-2: Send through the backend
- **Description**: The app uploads the audio to a backend function, which calls the
  provider with Zema's server-side key and returns the text, and the timings if any. The
  provider sits behind a `zema_core` interface so it can be changed later. The audio is
  deleted as soon as the answer is back.
- **Acceptance Criteria**: No provider key is in the app or the repo; calls are limited
  per install (and per account once 005 exists) per day.
- **Priority**: Must

### FR-3: Draft in the editor
- **Description**: The result opens in the contribution editor (006) as a draft, split
  into lines, with sections (verse, chorus) guessed where possible. It is marked "AI
  draft" until the user edits and submits it, and moderators see that it started as a
  draft.
- **Priority**: Must

### FR-4: Draft sync timing
- **Description**: Word or line timings from the provider prefill the sync editor for
  this recording, for the user to check.
- **Priority**: Should

### FR-5: Progress and failure
- **Description**: Upload and transcription progress, cancel, and clear messages for no
  internet, the daily limit, audio too long, and "couldn't hear any words".
- **Priority**: Must

---

## Non-Functional Requirements

### Performance
| Requirement | Metric | Target |
|-------------|--------|--------|
| Time to draft | 5-minute song, 4G | < 2 minutes (depends on the provider) |
| Upload size | 5-minute song | Compressed on the phone first (e.g. mono, low bitrate) |

### Privacy
| Requirement | Standard | Notes |
|-------------|----------|-------|
| Audio upload | Explicit consent each time | The only feature that sends audio; an exception to the app-wide "no audio uploaded" rule, which must be updated |
| Retention | — | Deleted after transcription; the provider must not keep or train on it (checked in the spike) |

### Security
| Requirement | Standard | Notes |
|-------------|----------|-------|
| Provider key | Server-side only | Held in the backend's secrets, never in the app or the repo |
| Abuse and cost | Rate limit | Per install per day, like reports; a monthly spend cap on the provider |

---

## Constraints

### Technical Constraints

**Project-wide standards**: Required standards will be loaded from memory-bank standards folder by Construction Agent

**Intent-specific constraints**:
- Only the public anon key in the app; the provider key lives in the backend.
- Generated lyrics are never published without a person's review (006's moderation).
- The provider is swappable behind an interface.

### Business Constraints
- Provider cost, and its terms for user audio and for copyrighted music.
- The privacy policy and store listing must mention the upload.

---

## Assumptions

| Assumption | Risk if Invalid | Mitigation |
|------------|-----------------|------------|
| Some service transcribes sung Amharic, Afaan Oromoo and Tigrinya usefully | Drafts too poor to help | Vocal separation first; ship for the languages that work; or drop the intent |
| Users accept sending audio for a draft | Little use | Clear consent and deletion; it stays optional |
| Costs stay low per song | Too expensive at scale | Daily limits, a spend cap, only songs with no lyrics |

---

## Open Questions

| Question | Owner | Due Date | Resolution |
|----------|-------|----------|------------|
| Which provider (or an on-phone model)? | Product owner | After the FR-0 spike | Pending |
| Daily limit per user, and who pays? | Product owner | Requirements review | Pending |
| Signed-in users only (needs 005)? | Product owner | Requirements review | Pending |
| Build before or after 006 (where the draft opens)? | Product owner | Requirements review | Pending |
