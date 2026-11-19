# Plan: 057-admin-website

- zema_core: `ModerationRepository`, `ModeratorReport`, `ModeratedSong`, `ReportStatus`, `reportReasonWire`.
- zema_data: `SupabaseModerationRepository` over bolt 054's RPCs; named refusals → `ContributionFailure(code)`.
- Backend: `moderator_song(id)` added to the 054 migration (not applied anywhere yet), so hidden songs' lyrics can be read.
- Reports page: status chips, Resolve / Dismiss, Open song → catalog. Catalog page: debounced search, Load more, detail with lyrics and recordings, Hide (confirm) / Restore.
