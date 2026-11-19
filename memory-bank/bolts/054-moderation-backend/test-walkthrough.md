# Tests: 054-moderation-backend

`supabase/tests/database/019_moderation.test.sql`, 29 tests: role checks (user, anon), report order, filter, paging, no hash, resolve, bad status, unknown report; song search by artist, paging, hide → out of `song_index`/`get_song` but still listed for moderators, drafts and unknown ids refused, edit of a hidden song not approvable, restore keeps `approved_at`.

`npx supabase test db`: 19 files, 637 tests, all pass.
