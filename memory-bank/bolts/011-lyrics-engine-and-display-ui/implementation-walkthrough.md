---
stage: implement
bolt: 011-lyrics-engine-and-display-ui
created: 2026-10-26T15:22:20Z
---

## Implementation Walkthrough: lyrics-engine-and-display-ui (bolt 3 of 9)

### Summary

The Search tab replaces "Coming soon" with search over the phone's songs, artists and albums while typing, using bolt 010's matching. It has filter chips and recent searches. Album and artist pages opened from Search stay in the Search tab, so Back returns to the results.

### Structure Overview

An index provider prepares a search key for every song, artist and album whenever the library changes. The screen asks it for results on each keystroke and shows them grouped (or one group, by chip). With the field empty it shows recent searches, which a small notifier keeps in shared preferences.

### Completed Work

- [x] `apps/mobile/lib/features/search/application/library_search.dart` - `LibrarySearchIndex` (songs by title, artists by name, albums by name and artist), ranked results (score, then text containing the query, then library order), `librarySearchIndexProvider`
- [x] `apps/mobile/lib/features/search/application/recent_searches.dart` - `RecentSearches`: newest first, max 10, one entry per normalized query, blanks ignored, remove one, clear, saved in shared preferences
- [x] `apps/mobile/lib/features/search/presentation/search_screen.dart` - access gate, field (submit saves the query), scope chips, grouped results with top 4 and See all under All, song rows with the song menu, artist and album rows, no-results state
- [x] `apps/mobile/lib/features/search/presentation/widgets/recent_searches_view.dart` - recent searches with remove and Clear all, or a hint when there are none
- [x] `apps/mobile/lib/features/library/presentation/widgets/artist_row.dart` - the artist row, moved out of the Artists view so Search can use it; opens the artist page in the current tab
- [x] `apps/mobile/lib/features/library/presentation/widgets/library_search_field.dart` - optional submit callback
- [x] `apps/mobile/lib/app/routes.dart`, `app/router.dart` - album and artist pages also under `/search`; `AppRoutes.album` / `artist` take a base, and `detailBase` picks it from the current location
- [x] `apps/mobile/lib/features/library/presentation/artist_screen.dart`, `artists_view.dart` - album links and artist rows stay in the current tab
- [x] `apps/mobile/lib/l10n/app_en.arb` - 10 Search strings; the Search "Coming soon" message removed
- [x] `apps/mobile/test/app/app_shell_test.dart` - the "Coming soon" and scroll-keeping tests now use Contribute, the last unbuilt tab

### Key Decisions

- **Songs are found by title only**: searching an artist's name lists the artist (with their songs one tap away) instead of filling Songs with every song by them.
- **Ties broken by the text itself**: among equal scores, results whose text contains the typed words come first. That handles bolt 010's known limit (same consonants) where it matters.
- **A query is remembered when it was useful**: when the search key is pressed or a result is opened, not on every keystroke.
- **Album and artist routes in both tabs**, so Search keeps its results and the navigation bar stays on Search.

### Deviations from Plan

None.

### Dependencies Added

None.

### Developer Notes

- Checked on the emulator: "amlak" finds Amlak; "bulk artist 1" lists Artists and Albums with See all; an album opens with the Search tab selected and Back returns to the results; the query appears in Recent searches after opening a result.
- Full suite passes (553 app tests) before the new Search tests.
