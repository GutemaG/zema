# Plan: 056-admin-website

- Contributions: queue (kind chips, reload) beside the selected item ≥ 900 px; a pushed page below. Reuses `ContributionRepository.queue/review` and zema_core's `changedLines`, `recordingsLosingTimings`, `expandPlayOrder`.
- Per kind: new song → lines (+ recording, timing); correction → changes, timings it drops, current and submitted side by side; recording/timing → source and a time–line table.
- Decision bar: note (required for request changes and reject), errors by code.
- Fingerprints: list with Approve / Reject (`reviewFingerprint`).
