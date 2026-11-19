# Fingerprint storage

How Zema stores audio fingerprints (intent 009) on the server and on the phone, and
how much room they take. Audio is never stored: only hashes, which can't be turned
back into sound.

## What a fingerprint is

`zema_core`'s `Fingerprinter` turns audio into a list of hashes:

1. The audio is resampled to 11,025 Hz and cut into **frames** of 256 samples, about
   43 frames per second.
2. In each frame, the strongest frequency peaks are found.
3. Each pair of nearby peaks becomes one **hash**: a 24-bit number (0 to 16,777,215).
   The hash keeps the frame of the first peak.

So a fingerprint is two lists of the same length: `hashes` and `frames`. How many
hashes per second depends on the density:

| Density | Hashes per second | Used for |
|---|---|---|
| Catalog | about 100 | Recordings in the server index, and on phones offline |
| Library offline | about 20 | The phone's own music files |
| Query | about 185 | The excerpt Listen hears through the microphone |

A 4½-minute song gives about 27,000 catalog hashes. `fingerprintVersion` (now 1) is
stored with every fingerprint. A new version means all fingerprints are made again.

## Server tables

| Table | One row per | Holds |
|---|---|---|
| `recording_fingerprints` | Recording | `version`, `frame_count`, `hash_count`, `revision` (raised on each replace), `identified` (how often Listen found it) |
| `fingerprint_hashes` | **Hash** | `hash`, `recording_id`, `frame`. Indexed by `hash` (for lookups) and by `recording_id` (for replacing) |
| `pending_fingerprints` | Fingerprint waiting for approval | The whole fingerprint as two `int[]` arrays, and either a `contribution_id` or an `install_key` |
| `identify_counts` | Key and day | Lookup counts for the daily limits. No query is stored |

All four have Row Level Security on and no policies: nothing is readable through the
API. Everything goes through the functions below.

### Why one row per hash

To identify an excerpt, `identify_audio` looks up each of its hashes in the `hash`
index. For every hash that appears in a recording, it adds a vote to
`recording frame − excerpt frame` (the shift). Many votes at the same shift mean that
recording, starting at that point. With one row per hash, this is a single indexed
join. A fingerprint stored as one value per recording would mean reading every
recording on each lookup.

## How a fingerprint gets in

```text
seed tool ──────────────────────────────────────────► put_fingerprint ─► recording_fingerprints
                                                                       └► fingerprint_hashes
contribution ─► attach_fingerprint ─► pending_fingerprints ─(approved)─┘
library song ─► share_fingerprint ──► pending_fingerprints ─(two agree, or a moderator)─┘
```

- **Seed tool** (`packages/zema_core/tool/upload_fingerprints.dart`, service key):
  fingerprints audio files on a computer and calls `put_fingerprint` directly.
- **Contributions:** after a file recording is sent for review, the phone calls
  `attach_fingerprint`. The row waits in `pending_fingerprints`. When a moderator
  approves the contribution, a trigger publishes it; on approval or rejection the
  pending row is deleted.
- **Library songs** (if the user agreed to share): the phone asks
  `missing_fingerprints` which of its linked recordings have none, then calls
  `share_fingerprint` for up to 5 at a time (at most 30 a day per install). When a
  second install sends a fingerprint that agrees with the first (at least 20 % of
  the hashes line up), it is published. Otherwise a moderator can publish or drop it
  from the review queue (`moderator_fingerprints`, `review_fingerprint`).

`put_fingerprint` replaces a recording's fingerprint: it keeps the
`recording_fingerprints` row (raising `revision`), deletes its old hashes and inserts
the new ones.

`fingerprint_error` checks every fingerprint sent by a phone: 100 to 120,000 hashes,
24-bit hashes, frames inside the recording, and a length within 3 s or 5 % of the
recording's.

### Uploads are off for now

While server storage is limited, phones send no fingerprints: contributions
and library sharing skip `attach_fingerprint` and `share_fingerprint`, and the
Share switch is hidden. Build with `--dart-define=ZEMA_FINGERPRINT_UPLOADS=true`
to turn them back on. The tables and functions stay; the seed tool still works.

## Lookups

`identify_audio(version, hashes, frames, install_id, …)` returns up to 3 approved
recordings, best first, with the shift (where the excerpt starts) and a score. It
needs at least 12 hashes lined up. Each call counts against the install (300 a day)
and the IP address (2,000 a day); past either it fails with HTTP 429. The top match's
`identified` count goes up by one.

## On the phone

| Drift table | Holds |
|---|---|
| `track_fingerprints` | The user's own files, at the library density, for offline Listen |
| `catalog_fingerprints` | Catalog recordings kept for offline Listen, with the server's `revision` |
| `pending_lookups` | Excerpts heard offline, kept as query fingerprints until the catalog can be asked |

`track_audio_matches` (v16) holds what each library file was identified as
by its **sound**: the song, the recording and how much later the file runs. Zema
decodes the first 105 s of a file with no lyrics linked, searches two 12 s
excerpts (about 26 s and 90 s in) among the library's and the kept catalog
fingerprints, and links the song only when both agree. A file being played is
also looked up on the server, which stores nothing. The others are checked in
the background after the library is fingerprinted. A link made by hand comes
first, then one by sound, then one by title.

Each fingerprint is one blob (`AudioFingerprint.toBytes`), about 6 bytes per hash:
roughly 160 KB for a 4½-minute catalog song.

Which catalog songs are kept (`OfflineBudget`, default 50 MB): favorites first, then
library songs, then the most identified. The phone lists them with
`offline_fingerprints`, fetches what's new or changed (by `revision`) with
`get_fingerprints`, 20 at a time, on Wi-Fi, at most every 12 hours.

## How much room it takes

Measured with one 271 s song (26,556 hashes):

| Part | Size |
|---|---|
| `fingerprint_hashes` rows | 1.8 MB |
| Its two indexes | 2.3 MB |
| **Per song** | **about 4 MB** (about 150 bytes per hash) |

The data itself is 12 bytes per hash. The rest is Postgres's overhead per row and per
index entry.

| Catalog | Rows | Server size |
|---|---|---|
| 1 song | 27 thousand | 4 MB |
| 100 songs | 2.7 million | 400 MB |
| 1,000 songs | 27 million | 4 GB |

The Supabase free plan allows 500 MB, so fingerprints fill it at about 100 songs.
`pending_fingerprints` adds about 210 KB per waiting fingerprint, until it's reviewed.

Ways to make it smaller, when needed:

- Lower the catalog density (for example to 50 per second): about half the size, with
  some loss on short or noisy excerpts. Needs a new `fingerprintVersion`.
- Drop very common hashes, which match almost everything and help little.
- A bigger plan or server (see [replacing-supabase.md](replacing-supabase.md)).
