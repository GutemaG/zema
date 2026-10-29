---
unit: 002-cloud-lyrics-catalog-ui
intent: 004-cloud-lyrics-catalog
created: 2026-10-29T08:32:46Z
last_updated: 2026-10-29T14:55:20Z
---

# Construction Log: cloud-lyrics-catalog-ui

## Original Plan

**From Inception**: 7 bolts planned
**Planned Date**: 2026-10-29T05:59:04Z

| Bolt ID | Stories | Type |
|---------|---------|------|
| 022-cloud-lyrics-catalog-ui | 001 | simple-construction-bolt |
| 023-cloud-lyrics-catalog-ui | 002 | simple-construction-bolt |
| 024-cloud-lyrics-catalog-ui | 003 | simple-construction-bolt |
| 025-cloud-lyrics-catalog-ui | 004 | simple-construction-bolt |
| 026-cloud-lyrics-catalog-ui | 005 | simple-construction-bolt |
| 027-cloud-lyrics-catalog-ui | 006, 007 | simple-construction-bolt |
| 028-cloud-lyrics-catalog-ui | 008 | simple-construction-bolt |

## Replanning History

| Date | Action | Change | Reason | Approved |
|------|--------|--------|--------|----------|

## Current Bolt Structure

| Bolt ID | Stories | Status | Changed |
|---------|---------|--------|---------|
| 022-cloud-lyrics-catalog-ui | 001 | ✅ completed | - |
| 023-cloud-lyrics-catalog-ui | 002 | ✅ completed | - |
| 024-cloud-lyrics-catalog-ui | 003 | ✅ completed | - |
| 025-cloud-lyrics-catalog-ui | 004 | ✅ completed | - |
| 026-cloud-lyrics-catalog-ui | 005 | ✅ completed | - |
| 027-cloud-lyrics-catalog-ui | 006, 007 | ✅ completed | - |
| 028-cloud-lyrics-catalog-ui | 008 | ✅ completed | - |

## Execution History

| Date | Bolt | Event | Details |
|------|------|-------|---------|
| 2026-10-29T08:32:46Z | 022-cloud-lyrics-catalog-ui | started | Stage 1: plan |
| 2026-10-29T08:34:38Z | 022-cloud-lyrics-catalog-ui | stage-complete | plan → implement |
| 2026-10-29T08:42:54Z | 022-cloud-lyrics-catalog-ui | stage-complete | implement → test |
| 2026-10-29T08:48:08Z | 022-cloud-lyrics-catalog-ui | completed | All 3 stages done; 288 pgTAP + 199 core + 28 zema_data + 650 app tests pass |
| 2026-10-29T08:49:53Z | 023-cloud-lyrics-catalog-ui | started | Stage 1: plan |
| 2026-10-29T08:50:56Z | 023-cloud-lyrics-catalog-ui | stage-complete | plan → implement |
| 2026-10-29T09:10:29Z | 023-cloud-lyrics-catalog-ui | stage-complete | implement → test |
| 2026-10-29T09:42:06Z | 023-cloud-lyrics-catalog-ui | completed | All 3 stages done; 201 core + 28 zema_data + 675 app tests pass; checked on the emulator |
| 2026-10-29T09:46:13Z | 024-cloud-lyrics-catalog-ui | started | Stage 1: plan |
| 2026-10-29T09:47:09Z | 024-cloud-lyrics-catalog-ui | stage-complete | plan → implement |
| 2026-10-29T10:56:31Z | 024-cloud-lyrics-catalog-ui | stage-complete | implement → test |
| 2026-10-29T11:19:05Z | 024-cloud-lyrics-catalog-ui | completed | All 3 stages done; 201 core + 28 zema_data + 704 app tests pass; checked on the emulator (v3→v4 upgrade, offline, Try again, cached) |
| 2026-10-29T11:24:42Z | 025-cloud-lyrics-catalog-ui | started | Stage 1: plan |
| 2026-10-29T11:26:11Z | 025-cloud-lyrics-catalog-ui | stage-complete | plan → implement |
| 2026-10-29T11:38:13Z | 025-cloud-lyrics-catalog-ui | stage-complete | implement → test |
| 2026-10-29T12:00:11Z | 025-cloud-lyrics-catalog-ui | completed | All 3 stages done; 201 core + 28 zema_data + 723 app tests pass; checked on the emulator (uncached line found, offline note, Try again); 3G timing not proven |
| 2026-10-29T12:09:08Z | 026-cloud-lyrics-catalog-ui | started | Stage 1: plan |
| 2026-10-29T12:12:51Z | 026-cloud-lyrics-catalog-ui | stage-complete | plan → implement |
| 2026-10-29T12:16:47Z | 026-cloud-lyrics-catalog-ui | stage-complete | implement → test |
| 2026-10-29T12:52:12Z | 026-cloud-lyrics-catalog-ui | completed | All 3 stages done; 201 core + 28 zema_data + 748 app tests pass; checked on the emulator (Download all, offline after restart, Clear keeps links) |
| 2026-10-29T12:55:28Z | 027-cloud-lyrics-catalog-ui | started | Stage 1: plan |
| 2026-10-29T12:55:53Z | 027-cloud-lyrics-catalog-ui | stage-complete | plan → implement |
| 2026-10-29T13:00:56Z | 027-cloud-lyrics-catalog-ui | stage-complete | implement → test |
| 2026-10-29T13:25:19Z | 027-cloud-lyrics-catalog-ui | completed | All 3 stages done; 201 core + 28 zema_data + 789 app tests pass; checked on the emulator (Recordings tab, report online, offline queue sent at restart, daily limit); a timed-out report can arrive twice (follow-up) |
| 2026-10-29T14:01:41Z | 028-cloud-lyrics-catalog-ui | started | Stage 1: plan |
| 2026-10-29T14:08:38Z | 028-cloud-lyrics-catalog-ui | stage-complete | plan → implement |
| 2026-10-29T14:15:39Z | 028-cloud-lyrics-catalog-ui | stage-complete | implement → test |
| 2026-10-29T14:55:20Z | 028-cloud-lyrics-catalog-ui | completed | All 3 stages done; 201 core + 28 zema_data + 810 app + 298 pgTAP tests pass; checked on the emulator (Home row, v5→v6 upgrade, a timed-out report stored once); intent done-when checks pass (3G search 247–621 ms via throttling proxy, 5,000-song index 347 KB gzip) |

## Notes
- Bolt 022: zema_data (SupabaseCatalogRepository, no dart:io) with typed failures; song_index() added to the backend (scope addition for FR-6); app reads ZEMA_BACKEND_URL/KEY from --dart-define, no key committed (tool/backend_env.sh writes a gitignored file); emulator check deferred to 023/024.
- Bolt 023: song index in Drift v3 (catalog_songs; v4/v5 for cache and reports); CatalogIndexRefresher (6 h, force, shared runs); linking and the picker use the index via SongIdentity; pull to refresh in Search; emulator found and fixed a scroll-physics bug; failing widget tests can hang a run (not investigated).
- Bolt 024: lyrics cache in Drift v4 (cached_songs, one JSON document per song, so nothing partial); CatalogLyricsRepository behind lyricsRepositoryProvider (version check, old copy offline, shared fetches); songProvider; C07 offline with Try again in Now Playing, the artwork panel and song detail; Riverpod auto-retry turned off for lyrics; sample lyrics moved to test fixtures; line search covers cached songs until 025.
- Bolt 025: Search's Lyrics group merges catalog titles (index, offline too), server lines (300 ms debounce, per-query auto-dispose provider, so stale answers drop) and downloaded songs' lines; C07 note with Try again when offline or failing; emulator umts didn't throttle host traffic, so < 1 s on 3G is estimated, not measured.
- Bolt 026: Settings → Lyrics shows storage used (count + JSON length), Download all (kept-alive LyricsDownloader, batches of 4, Cancel between batches, a failure keeps what finished) and Clear (confirm dialog; clears Drift and memory, invalidates songProvider; links and index kept).
- Bolt 027: reports of wrong lyrics (sheet from Song detail menu and Now Playing options; Drift v5 queued_reports; ReportSender flushes at startup and before each report; drops reports for songs off the index or refused for good; install ID in prefs) and Song detail's Recordings tab (usedRecording shared with the lyrics view). Follow-up: a report that times out can reach the server and be resent from the queue; needs a client report ID that submit_report ignores when repeated (backend migration).
- Bolt 028: Home 'New lyrics from the community' row (newLyricsProvider: newest 10 by approvedAt; LetterTile + Synced/Text only badge; Song detail in the Home tab) and story 009 (report IDs: reports.client_id unique per install hash; submit_report answers a repeat with the first id, before the limit; Drift v6 queued_reports.report_id, existing rows given a UUID in SQL). Intent done-when checks all pass; the concurrent-copy fallback in submit_report is reviewed, not tested.
