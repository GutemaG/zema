---
stage: plan
bolt: 059-track-print-core
created: 2026-11-19T19:30:00Z
---

## Implementation Plan: track print (story 002)

### Deliverables

`zema_core`, `lib/src/audio/track_print.dart`:

- `TrackPrinter.print(Float32List pcm)` takes the audio at `fingerprintSampleRate`, the
  rate the phone already decodes at, and returns a `TrackPrint`:
  - It halves the audio to ~5.5 kHz and uses the first 120 s.
  - It takes 2,048-sample windows every `hop` samples, and the energy in 33 bands
    from 300 to 2,000 Hz.
  - Each frame gives one 32-bit value: bit m is the sign of the band-energy
    difference between bands m and m+1, minus the same difference in the frame
    before (Philips, as in the earlier test).
- `TrackPrint`: `version` (`trackPrintVersion` = 1), `duration` and
  `values` (`Uint32List`), with `toBytes` / `fromBytes`.
- `printDistance(a, b)` returns the share of differing bits at the best shift
  within ±2 s, and the shift. It needs at least 30 s of overlap.
- `printKeys(print, {stride})` returns the index keys for the server: the top 20
  bits of every `stride`-th value. A copy shares some exact keys with the original,
  and bolt 060 then compares only those candidates.

`zema_core/tool/track_print_eval.dart` (needs ffmpeg) reads a folder of files and
prints:

- **Copies:** each file is compared to its 128 and 64 kbps MP3 and 128 kbps AAC
  re-encodes, and to starts trimmed by 0.3, 1 and 2 s. The bit differences
  and the shared keys are printed.
- **Different files:** every pair of files is compared. Pairs below the threshold are
  listed, since the folders may hold the same song twice; I'll listen to those.
- **The gap:** the worst copy against the closest different file, with sizes and
  printing time.

### Choices the eval makes

- **`hop`:** 512 samples (~93 ms, ~5 KB per print) or 256 samples (~46 ms,
  ~10 KB). A smaller hop handles trimmed starts better, since frames line up
  more closely. I'll pick the smallest print that keeps the gap.
- **`stride`** for the keys: the largest that still gives every copy at least 5
  shared keys. This sets the index size in bolt 060.

### Gate (from the story)

It **passes** if one threshold separates every copy from every truly different
file, with a margin of at least 5 points of bit difference. Otherwise I stop and
report; the fallback is landmark windows.

### Acceptance

- Unit tests:
  - A print is ≤ 10 KB and survives `toBytes` / `fromBytes`.
  - A copy shifted by a whole number of frames gives distance 0 at that shift.
  - Noise gives about 50 %.
  - Short audio is handled.
- Printing 120 s takes < 1 s on this machine. A phone is ~3–5× slower, so the target
  here is < 250 ms.
