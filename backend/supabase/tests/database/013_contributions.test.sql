-- Contributions (bolt 039): submitted and resubmitted only through the RPCs,
-- checked against the shared rules and the limits, readable by their author.
begin;
create extension if not exists pgtap with schema extensions;

select plan(89);

insert into auth.users (id, email) values
  ('00000000-0000-0000-0000-0000000000a1', 'a@example.com'),
  ('00000000-0000-0000-0000-0000000000b1', 'b@example.com'),
  ('00000000-0000-0000-0000-0000000000b2', 'b2@example.com'),
  ('00000000-0000-0000-0000-0000000000b3', 'b3@example.com');

-- A song singing 4 lines: verse (2 lines), chorus (1 line) twice.
create function pg_temp.song(id text default 'selam') returns jsonb language sql as $$
  select jsonb_build_object(
    'id', id,
    'title', 'Selam',
    'sections', jsonb_build_array(
      jsonb_build_object('id', 'v', 'kind', 'verse', 'lines',
        jsonb_build_array(jsonb_build_object('text', 'a'), jsonb_build_object('text', 'b'))),
      jsonb_build_object('id', 'c', 'kind', 'chorus', 'lines',
        jsonb_build_array(jsonb_build_object('text', 'c')))),
    'playOrder', jsonb_build_array('v', 'c', 'c'))
$$;

create function pg_temp.rec(id text, song text, source text default 'localFile')
returns jsonb language sql as $$
  select jsonb_build_object('id', id, 'songId', song, 'source', source, 'durationMs', 60000)
    || case when source = 'youtube' then jsonb_build_object('youtubeId', 'dQw4w9WgXcQ')
       else jsonb_build_object('fileName', 'Selam.mp3') end
$$;

create function pg_temp.timing(rec text, starts int[] default '{1000,2000,3000,4000}')
returns jsonb language sql as $$
  select jsonb_build_object('recordingId', rec, 'startsMs', to_jsonb(starts))
$$;

-- A new_song payload with [song], and optionally a recording and its timing.
create function pg_temp.new_song(
  song jsonb default pg_temp.song(),
  rec jsonb default null,
  timing jsonb default null
) returns jsonb language sql as $$
  select jsonb_strip_nulls(jsonb_build_object(
    'song', song,
    'recordings', case when rec is null then null else jsonb_build_array(rec) end,
    'timings', case when timing is null then null else jsonb_build_array(timing) end))
$$;

create function pg_temp.err(
  kind public.contribution_kind,
  payload jsonb,
  song_id text default null,
  base_version integer default null
) returns text language sql as $$
  select public.contribution_error(kind, song_id, base_version, payload)
$$;

-- An approved song with a local and a YouTube recording, and a draft song.
select public.seed_song(jsonb_build_object(
  'song', pg_temp.song('test-song'),
  'recordings', jsonb_build_array(
    pg_temp.rec('test-rec', 'test-song'),
    pg_temp.rec('test-yt', 'test-song', 'youtube'))));
select public.seed_song(jsonb_build_object('song', pg_temp.song('test-draft')), 'draft');

create function pg_temp.version() returns integer language sql as $$
  select version from public.songs where id = 'test-song'
$$;

-- Sung lines. --------------------------------------------------------------------

select is(public.sung_line_count(pg_temp.song()), 4, 'play order lines are counted per entry');
select is(public.sung_line_count(pg_temp.song() - 'playOrder'), 3, 'no play order: every section once');

-- Valid payloads. ----------------------------------------------------------------

select is(pg_temp.err('new_song', pg_temp.new_song()), null, 'a new song with lyrics only');
select is(
  pg_temp.err('new_song', pg_temp.new_song(rec => pg_temp.rec('r1', 'selam'), timing => pg_temp.timing('r1'))),
  null, 'a new song with a recording and its timing');
select is(
  pg_temp.err('new_song', pg_temp.new_song(rec => pg_temp.rec('r1', 'selam', 'youtube'))),
  null, 'a new song with a YouTube recording');
select is(
  pg_temp.err('edit_lyrics', jsonb_build_object('song', pg_temp.song('test-song')), 'test-song', pg_temp.version()),
  null, 'a correction based on the current version');
select is(
  pg_temp.err('recording', jsonb_build_object(
    'recordings', jsonb_build_array(pg_temp.rec('r2', 'test-song')),
    'timings', jsonb_build_array(pg_temp.timing('r2'))), 'test-song'),
  null, 'a recording with its timing');
select is(
  pg_temp.err('sync_timing', jsonb_build_object('timings', jsonb_build_array(pg_temp.timing('test-rec'))), 'test-song'),
  null, 'a timing for an existing recording');

-- Shape. -------------------------------------------------------------------------

select is(pg_temp.err('new_song', '[1]'), 'bad_payload', 'a payload that is not an object');
select is(pg_temp.err('new_song', null), 'bad_payload', 'no payload');
select is(
  pg_temp.err('new_song', pg_temp.new_song() || jsonb_build_object('recordings',
    jsonb_build_array(pg_temp.rec('r1', 'selam'), pg_temp.rec('r2', 'selam')))),
  'bad_payload', 'two recordings');
select is(
  pg_temp.err('new_song', pg_temp.new_song(jsonb_set(pg_temp.song(), '{id}', '"Not A Slug"'))),
  'bad_payload', 'a song ID that is not a slug');
select is(
  pg_temp.err('new_song', pg_temp.new_song(jsonb_set(pg_temp.song(), '{title}', '7'))),
  'bad_payload', 'a title that is not a string');

-- The song. ----------------------------------------------------------------------

select is(pg_temp.err('new_song', pg_temp.new_song(jsonb_set(pg_temp.song(), '{title}', '"   "'))),
  'title_required', 'a blank title');
select is(pg_temp.err('new_song', pg_temp.new_song(pg_temp.song() - 'title')),
  'title_required', 'no title');
select is(pg_temp.err('new_song', pg_temp.new_song(jsonb_set(pg_temp.song(), '{title}', to_jsonb(repeat('t', 200))))),
  null, 'a 200-character title');
select is(pg_temp.err('new_song', pg_temp.new_song(jsonb_set(pg_temp.song(), '{title}', to_jsonb(repeat('t', 201))))),
  'title_too_long', 'a 201-character title');
select is(pg_temp.err('new_song', pg_temp.new_song(pg_temp.song() || jsonb_build_object('artist', repeat('a', 201)))),
  'field_too_long', 'a 201-character artist');
select is(pg_temp.err('new_song', pg_temp.new_song(jsonb_set(pg_temp.song(), '{sections,0,lines,0,text}', to_jsonb(repeat('l', 501))))),
  'field_too_long', 'a 501-character line');
select is(pg_temp.err('new_song', pg_temp.new_song(jsonb_set(pg_temp.song(), '{sections}', '[]'))),
  'no_sections', 'no sections');
select is(pg_temp.err('new_song', pg_temp.new_song(jsonb_set(pg_temp.song(), '{sections,0,lines}', '[]'))),
  'empty_section', 'a section with no lines');
select is(pg_temp.err('new_song', pg_temp.new_song(jsonb_set(pg_temp.song(), '{sections,0,lines,1,text}', '" "'))),
  'empty_section', 'a blank line');
select is(pg_temp.err('new_song', pg_temp.new_song(jsonb_set(pg_temp.song(), '{sections,0,kind}', '"intro"'))),
  'bad_section', 'an unknown section kind');
select is(pg_temp.err('new_song', pg_temp.new_song(jsonb_set(pg_temp.song(), '{sections,1,id}', '"v"'))),
  'bad_section', 'two sections with the same ID');
select is(
  pg_temp.err('new_song', pg_temp.new_song(jsonb_set(pg_temp.song(), '{sections,0,lines}',
    (select jsonb_agg(jsonb_build_object('text', 'l' || i)) from generate_series(1, 299) i)))),
  null, '300 written lines');
select is(
  pg_temp.err('new_song', pg_temp.new_song(jsonb_set(pg_temp.song(), '{sections,0,lines}',
    (select jsonb_agg(jsonb_build_object('text', 'l' || i)) from generate_series(1, 300) i)))),
  'too_many_lines', '301 written lines');
select is(pg_temp.err('new_song', pg_temp.new_song(jsonb_set(pg_temp.song(), '{playOrder}', '[]'))),
  'play_order_empty', 'an empty play order');
select is(pg_temp.err('new_song', pg_temp.new_song(pg_temp.song() - 'playOrder')),
  'play_order_empty', 'no play order');
select is(pg_temp.err('new_song', pg_temp.new_song(jsonb_set(pg_temp.song(), '{playOrder,1}', '"x"'))),
  'play_order_unknown_section', 'a play order naming a missing section');

-- The recording. -----------------------------------------------------------------

select is(pg_temp.err('new_song', pg_temp.new_song(rec => pg_temp.rec('r1', 'selam', 'bundled'))),
  'bad_recording', 'a bundled recording');
select is(pg_temp.err('new_song', pg_temp.new_song(rec => pg_temp.rec('r1', 'selam') - 'fileName')),
  'bad_recording', 'a local file without its name');
select is(pg_temp.err('new_song', pg_temp.new_song(rec => jsonb_set(pg_temp.rec('r1', 'selam'), '{durationMs}', '0'))),
  'bad_recording', 'a zero duration');
select is(pg_temp.err('new_song', pg_temp.new_song(rec => pg_temp.rec('r1', 'other-song'))),
  'bad_recording', 'a recording of another song');
select is(pg_temp.err('new_song', pg_temp.new_song(rec => pg_temp.rec('R 1', 'selam'))),
  'bad_recording', 'a recording ID that is not a slug');
select is(pg_temp.err('new_song', pg_temp.new_song(rec => jsonb_set(pg_temp.rec('r1', 'selam', 'youtube'), '{youtubeId}', '"short"'))),
  'bad_video_id', 'a YouTube ID that is not 11 characters');
select is(pg_temp.err('new_song', pg_temp.new_song(rec => pg_temp.rec('r1', 'selam', 'youtube') - 'youtubeId')),
  'bad_video_id', 'a YouTube recording without its ID');

-- Timings. -----------------------------------------------------------------------

select is(pg_temp.err('new_song', pg_temp.new_song(rec => pg_temp.rec('r1', 'selam'), timing => pg_temp.timing('r1', '{1000,2000,3000}'))),
  'timing_count', 'fewer starts than sung lines');
select is(pg_temp.err('new_song', pg_temp.new_song(rec => pg_temp.rec('r1', 'selam'), timing => pg_temp.timing('r1', '{1000,2000,2000,4000}'))),
  'timing_order', 'two lines starting at the same time');
select is(pg_temp.err('new_song', pg_temp.new_song(rec => pg_temp.rec('r1', 'selam'), timing => pg_temp.timing('r1', '{-1,2000,3000,4000}'))),
  'timing_order', 'a negative start');
select is(pg_temp.err('new_song', pg_temp.new_song(rec => pg_temp.rec('r1', 'selam'), timing => pg_temp.timing('r1', '{1000,2000,3000,60000}'))),
  'timing_past_duration', 'a start at the end of the recording');
select is(
  pg_temp.err('new_song', pg_temp.new_song(rec => pg_temp.rec('r1', 'selam') - 'durationMs', timing => pg_temp.timing('r1', '{1000,2000,3000,90000}'))),
  null, 'any start when the duration is unknown');
select is(
  pg_temp.err('new_song', pg_temp.new_song(rec => pg_temp.rec('r1', 'selam'),
    timing => jsonb_build_object('recordingId', 'r1', 'startsMs', '[1000, 2000.5, 3000, 4000]'::jsonb))),
  'bad_payload', 'a start that is not a whole number');
select is(pg_temp.err('new_song', pg_temp.new_song(rec => pg_temp.rec('r1', 'selam', 'youtube'), timing => pg_temp.timing('r1'))),
  'youtube_not_synced', 'a timing for a YouTube recording');
select is(pg_temp.err('new_song', pg_temp.new_song(rec => pg_temp.rec('r1', 'selam'), timing => pg_temp.timing('r9'))),
  'unknown_recording', 'a timing for another recording');

-- Kinds and songs. ---------------------------------------------------------------

select is(pg_temp.err('new_song', '{}'), 'missing_song', 'a new song without its song');
select is(pg_temp.err('new_song', pg_temp.new_song(timing => pg_temp.timing('r1'))),
  'missing_recording', 'a new song with a timing but no recording');
select is(pg_temp.err('new_song', pg_temp.new_song(), 'test-song'),
  'song_not_allowed', 'a new song naming an existing song');
select is(pg_temp.err('new_song', pg_temp.new_song(), base_version => 1),
  'bad_base_version', 'a new song with a base version');
select is(pg_temp.err('edit_lyrics', jsonb_build_object('song', pg_temp.song('nope')), 'nope', 1),
  'unknown_song', 'a correction of an unknown song');
select is(pg_temp.err('edit_lyrics', jsonb_build_object('song', pg_temp.song('test-draft')), 'test-draft', 1),
  'unknown_song', 'a correction of a song that is not approved');
select is(pg_temp.err('sync_timing', '{}', 'Not A Slug'),
  'unknown_song', 'a malformed song ID');
select is(pg_temp.err('edit_lyrics', jsonb_build_object('song', pg_temp.song('test-song')), 'test-song'),
  'bad_base_version', 'a correction without a base version');
select is(pg_temp.err('edit_lyrics', jsonb_build_object('song', pg_temp.song('test-song')), 'test-song', pg_temp.version() + 1),
  'bad_base_version', 'a correction based on a future version');
select is(pg_temp.err('edit_lyrics', '{}', 'test-song', 1),
  'missing_song', 'a correction without its song');
select is(pg_temp.err('edit_lyrics', jsonb_build_object('song', pg_temp.song('other')), 'test-song', 1),
  'bad_payload', 'a correction whose song ID differs');
select is(pg_temp.err('recording', '{}', 'test-song'),
  'missing_recording', 'a recording contribution without its recording');
select is(pg_temp.err('recording', jsonb_build_object('recordings', jsonb_build_array(pg_temp.rec('test-rec', 'test-song'))), 'test-song'),
  'bad_recording', 'a recording ID that already exists');
select is(pg_temp.err('sync_timing', '{}', 'test-song'),
  'missing_timing', 'a sync without its timing');
select is(pg_temp.err('sync_timing', jsonb_build_object('timings', jsonb_build_array(pg_temp.timing('nope'))), 'test-song'),
  'unknown_recording', 'a sync for an unknown recording');
select is(pg_temp.err('sync_timing', jsonb_build_object('timings', jsonb_build_array(pg_temp.timing('test-yt'))), 'test-song'),
  'youtube_not_synced', 'a sync for a YouTube recording');
select is(pg_temp.err('sync_timing', jsonb_build_object('timings', jsonb_build_array(pg_temp.timing('test-rec', '{1,2}'))), 'test-song'),
  'timing_count', 'a sync counted against the current song');

-- Submitting. --------------------------------------------------------------------

set local role authenticated;
set local request.jwt.claims = '{"sub": "00000000-0000-0000-0000-0000000000a1", "role": "authenticated"}';

select isnt(public.submit_contribution('new_song', pg_temp.new_song()), null, 'a user submits a new song');
select lives_ok(
  $$select public.submit_contribution('edit_lyrics', jsonb_build_object('song', pg_temp.song('test-song')), 'test-song', pg_temp.version());
    select public.submit_contribution('recording', jsonb_build_object('recordings', jsonb_build_array(pg_temp.rec('r2', 'test-song'))), 'test-song');
    select public.submit_contribution('sync_timing', jsonb_build_object('timings', jsonb_build_array(pg_temp.timing('test-rec'))), 'test-song')$$,
  'and a correction, a recording and a sync');
select set_eq(
  $$select kind::text, status::text, author_id, revision, submitted_at = now()
    from public.contributions$$,
  $$values
    ('new_song', 'pending', '00000000-0000-0000-0000-0000000000a1'::uuid, 1, true),
    ('edit_lyrics', 'pending', '00000000-0000-0000-0000-0000000000a1'::uuid, 1, true),
    ('sync_timing', 'pending', '00000000-0000-0000-0000-0000000000a1'::uuid, 1, true),
    ('recording', 'pending', '00000000-0000-0000-0000-0000000000a1'::uuid, 1, true)$$,
  'each is pending, by its author, at revision 1');
select is(
  (select base_version from public.contributions where kind = 'edit_lyrics'),
  pg_temp.version(), 'the correction keeps its base version');
select throws_ok(
  $$select public.submit_contribution('new_song', pg_temp.new_song(pg_temp.song() - 'title'))$$,
  '22023', 'title_required', 'a broken rule is raised with its code');

-- 256 KB, padded with a key the rules ignore.
create function pg_temp.of_size(n int) returns jsonb language sql as $$
  select pg_temp.new_song() || jsonb_build_object('pad',
    repeat('p', n - octet_length((pg_temp.new_song() || '{"pad": ""}')::text)))
$$;
select lives_ok($$select public.submit_contribution('new_song', pg_temp.of_size(262144))$$, 'exactly 256 KB is accepted');
select is((select max(size_bytes) from public.contributions), 262144, 'and its size is recorded');
select throws_ok($$select public.submit_contribution('new_song', pg_temp.of_size(262145))$$,
  '54000', 'payload_too_large', 'one byte more is refused');

-- Direct writes. -----------------------------------------------------------------

select throws_ok(
  $$insert into public.contributions (author_id, kind, payload) values (auth.uid(), 'new_song', '{}')$$,
  '42501', null, 'a user cannot insert into contributions');
select throws_ok($$update public.contributions set status = 'approved'$$, '42501', null, 'or update it');
select throws_ok($$delete from public.contributions$$, '42501', null, 'or delete from it');

-- Guests. ------------------------------------------------------------------------

set local request.jwt.claims = '{"role": "authenticated"}';
select throws_ok($$select public.submit_contribution('new_song', pg_temp.new_song())$$,
  '28000', 'not_signed_in', 'no user: not signed in');
set local role anon;
select throws_ok($$select public.submit_contribution('new_song', pg_temp.new_song())$$,
  '42501', null, 'anon cannot call submit');
select is_empty('select * from public.contributions', 'anon reads no contributions');

-- Other users. -------------------------------------------------------------------

set local role authenticated;
set local request.jwt.claims = '{"sub": "00000000-0000-0000-0000-0000000000b1", "role": "authenticated"}';
select is_empty('select * from public.contributions', 'another user sees none of them');
select public.submit_contribution('new_song', pg_temp.new_song());
select results_eq(
  'select author_id from public.contributions',
  $$values ('00000000-0000-0000-0000-0000000000b1'::uuid)$$,
  'and sees only their own');

-- Limits. ------------------------------------------------------------------------

-- b1 has 1 pending; 18 more pending and 1 sent back make 20 open.
reset role;
insert into public.contributions (author_id, kind, payload, status)
select '00000000-0000-0000-0000-0000000000b1', 'new_song', '{}',
  case when i = 1 then 'changes_requested' else 'pending' end::public.contribution_status
from generate_series(1, 19) i;
set local role authenticated;
select throws_ok($$select public.submit_contribution('new_song', pg_temp.new_song())$$,
  'PT429', 'too_many_open', 'the 21st open contribution is refused');
reset role;
update public.contributions set status = 'approved'
where id = (select id from public.contributions
  where author_id = '00000000-0000-0000-0000-0000000000b1' and status = 'pending' limit 1);
set local role authenticated;
select lives_ok($$select public.submit_contribution('new_song', pg_temp.new_song())$$,
  'reviewed ones no longer count');

-- b2: 29 reviewed today, so the 30th goes through and the 31st doesn't.
reset role;
insert into public.contributions (author_id, kind, payload, status)
select '00000000-0000-0000-0000-0000000000b2', 'new_song', '{}', 'approved'
from generate_series(1, 29);
-- b3: 30 from yesterday, which no longer count.
insert into public.contributions (author_id, kind, payload, status, created_at)
select '00000000-0000-0000-0000-0000000000b3', 'new_song', '{}', 'approved', now() - interval '25 hours'
from generate_series(1, 30);
set local role authenticated;
set local request.jwt.claims = '{"sub": "00000000-0000-0000-0000-0000000000b2", "role": "authenticated"}';
select lives_ok($$select public.submit_contribution('new_song', pg_temp.new_song())$$,
  'the 30th in 24 hours is accepted');
select throws_ok($$select public.submit_contribution('new_song', pg_temp.new_song())$$,
  'PT429', 'too_many_today', 'the 31st is refused');
set local request.jwt.claims = '{"sub": "00000000-0000-0000-0000-0000000000b3", "role": "authenticated"}';
select lives_ok($$select public.submit_contribution('new_song', pg_temp.new_song())$$,
  'older than 24 hours does not count');

-- Resubmitting. ------------------------------------------------------------------

reset role;
create temp table sent_back as
  select id from public.contributions
  where author_id = '00000000-0000-0000-0000-0000000000a1' and kind = 'new_song'
  order by created_at limit 1;
grant select on sent_back to authenticated;
update public.contributions
set status = 'changes_requested', review_note = 'Fix the chorus',
    submitted_at = now() - interval '1 day'
where id = (select id from sent_back);

set local role authenticated;
set local request.jwt.claims = '{"sub": "00000000-0000-0000-0000-0000000000b1", "role": "authenticated"}';
select throws_ok(
  $$select public.resubmit_contribution((select id from sent_back), pg_temp.new_song())$$,
  '22023', 'not_editable', 'another user cannot resubmit it');

set local request.jwt.claims = '{"sub": "00000000-0000-0000-0000-0000000000a1", "role": "authenticated"}';
select throws_ok(
  $$select public.resubmit_contribution((select id from sent_back), pg_temp.new_song(pg_temp.song() - 'title'))$$,
  '22023', 'title_required', 'a resubmit breaking a rule is refused');
select is(
  (select status::text from public.contributions where id = (select id from sent_back)),
  'changes_requested', 'and changes nothing');
select is(
  public.resubmit_contribution((select id from sent_back),
    pg_temp.new_song(jsonb_set(pg_temp.song(), '{title}', '"Selam 2"'))),
  2, 'the author resubmits it: revision 2');
select results_eq(
  $$select status::text, payload #>> '{song,title}', review_note, submitted_at = now()
    from public.contributions where id = (select id from sent_back)$$,
  $$values ('pending', 'Selam 2', 'Fix the chorus', true)$$,
  'pending again, with the new payload and time; the note stays');
select throws_ok(
  $$select public.resubmit_contribution((select id from sent_back), pg_temp.new_song())$$,
  '22023', 'not_editable', 'a pending contribution cannot be resubmitted');
select throws_ok(
  $$select public.resubmit_contribution(gen_random_uuid(), pg_temp.new_song())$$,
  '22023', 'not_editable', 'nor an unknown one');

select * from finish();
rollback;
