---
intent: 013-track-identification
phase: inception
status: units-decomposed
created: 2026-11-19T16:00:00Z
updated: 2026-11-19T16:00:00Z
---

# Requirements: Identify Badly Tagged Tracks

> Source: product owner, 2026-11-19. Research and a bitrate test on the owner's
> files (re-encodes 0.3–13 % bits apart, different songs 49.5 %).

## Intent Overview

A library file whose tags don't name the song ("Track 01", "@channel", no tags) gets
its lyrics anyway: first by cleaning its title and artist, then by a small whole-track
fingerprint (a **track print**) looked up in Zema's own catalog. Files that already
match by title share their print, so the well-tagged majority identifies the rest.
No third-party identification service.

## Business Goals

| Goal | Success Metric | Priority |
|------|----------------|----------|
| Untagged copies get lyrics | A re-encoded, untagged copy of a song someone has linked is linked on play | Must |
| Fit the free plan | ≤ 10 KB per print on the server | Must |
| No wrong lyrics | No different-song pair passes the threshold in the eval | Must |

## Functional Requirements

### FR-1: Clean title and artist
Before title matching (`SongMatcher`, which already finds the title inside noise and
uses transliterations): drop `@channel`, `[...]`, `(128)`, YouTube IDs, "Track N",
"CD N"; ignore channel-name artists and albums; move a known catalog artist found in
the title out of it; with empty tags, read the file name (track numbers, `_`, ` - `).
A recording length within 3 s breaks ties.

### FR-2: Track print
`zema_core` makes a print from the first 110 s: 32-bit values (band energy
differences, Philips/Chromaprint family) and compares two prints by the share of
differing bits over the best shift. An eval on the owner's music folder sets the
threshold: re-encodes (320/128/64 kbps MP3, AAC) and starts trimmed by up to 2 s
match; different songs never. **Gate:** if the eval fails, stop and revisit.

### FR-3: Store and match on the server
`track_prints` (song, print, keys, duration, status, installs), with an index on the
keys. `match_track(print, duration, install_id)` returns up to 3 songs with a score;
daily limits per install and IP as `identify_audio`. Nothing readable via the API.

### FR-4: Sharing
With the user's consent (the existing Share switch): after a file links by title or
by hand, the phone sends its print (`share_track_print`). A print is published when a
second install sends one that matches it, or a moderator approves it; at most 30 a day
per install. Contributions with a file recording and the seed tool send one too.

### FR-5: Identify on the phone
A track with no link (manual, sound or title) is printed on play and in the
background scan, and looked up with `match_track`; the answer is kept as a link
below title (manual → sound → title → print). Offline: looked up later.
Unlinking stays one tap.

### FR-6: Review shared prints
The admin site's Fingerprints page also lists pending track prints (song, installs,
length) to approve or reject.

## Non-Functional Requirements

| Area | Requirement |
|------|-------------|
| Size | ≤ 10 KB per print; 10,000 songs ≤ 100 MB |
| Speed | `match_track` < 300 ms at 10,000 prints; printing a song < 1 s on a mid phone |
| Privacy | Only prints leave the phone, only with consent; no audio |

## Constraints

- No third-party identification APIs (owner, 2026-11-19).
- Landmark hashes stay for Listen; their uploads stay off.
- Hosted migrations only after the owner confirms.

## Out of Scope

Covers, live versions, microphone excerpts, neural embeddings, AcoustID/ShazamKit/ACRCloud.

## Open Questions

| Question | Resolution |
|----------|------------|
| Print per song or per recording | Per song, several allowed (files linked by title have no recording) |
| Print length | 110 s at a 46 ms hop (≤ 10 KB); eval passed, bolt 059 |
