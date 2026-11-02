-- Publishing (bolt 041): approving a contribution puts it in the catalog in
-- the same transaction; a failure leaves it pending and the catalog unchanged.
begin;
create extension if not exists pgtap with schema extensions;

select plan(40);

insert into auth.users (id, email) values
  ('00000000-0000-0000-0000-0000000000a1', 'a@example.com'),
  ('00000000-0000-0000-0000-0000000000d1', 'mod@example.com');
insert into public.user_roles (user_id, role) values
  ('00000000-0000-0000-0000-0000000000d1', 'moderator');

-- The moderator reviews; the owner's role inserts and reads (auth.uid() reads
-- the claims whatever the role).
set local request.jwt.claims = '{"sub": "00000000-0000-0000-0000-0000000000d1", "role": "authenticated"}';

-- Sings 4 lines: verse (2), chorus (1) twice.
create function pg_temp.song(id text default 'selam', title text default 'Selam') returns jsonb language sql as $$
  select jsonb_build_object(
    'id', id, 'title', title,
    'sections', jsonb_build_array(
      jsonb_build_object('id', 'v', 'kind', 'verse', 'lines',
        jsonb_build_array(jsonb_build_object('text', 'a'), jsonb_build_object('text', 'b'))),
      jsonb_build_object('id', 'c', 'kind', 'chorus', 'lines',
        jsonb_build_array(jsonb_build_object('text', 'c')))),
    'playOrder', jsonb_build_array('v', 'c', 'c'))
$$;
create function pg_temp.rec(id text, song text, source text default 'localFile') returns jsonb language sql as $$
  select jsonb_build_object('id', id, 'songId', song, 'source', source, 'durationMs', 60000)
    || case when source = 'youtube' then jsonb_build_object('youtubeId', 'dQw4w9WgXcQ')
       else jsonb_build_object('fileName', id || '.mp3') end
$$;
create function pg_temp.timing(rec text, starts int[] default '{1000,2000,3000,4000}') returns jsonb language sql as $$
  select jsonb_build_object('recordingId', rec, 'startsMs', to_jsonb(starts))
$$;
create function pg_temp.add(kind public.contribution_kind, payload jsonb, song text default null,
  base integer default null) returns uuid language sql as $$
  insert into public.contributions (author_id, kind, payload, song_id, base_version)
  values ('00000000-0000-0000-0000-0000000000a1', kind, payload, song, base)
  returning id
$$;
create function pg_temp.approve(id uuid) returns text language sql as $$
  select public.review_contribution(id, 'approved')
$$;
create function pg_temp.version(song text default 'test-song') returns integer language sql as $$
  select version from public.songs where id = song
$$;
create function pg_temp.starts(rec text) returns int[] language sql as $$
  select starts_ms from public.sync_timings where recording_id = rec
$$;

-- An approved song: test-rec timed, test-rec2 not timed.
select public.seed_song(jsonb_build_object(
  'song', pg_temp.song('test-song'),
  'recordings', jsonb_build_array(pg_temp.rec('test-rec', 'test-song'), pg_temp.rec('test-rec2', 'test-song')),
  'timings', jsonb_build_array(pg_temp.timing('test-rec'))));

-- New songs. ------------------------------------------------------------------------

create temp table new1 as select pg_temp.add('new_song', jsonb_build_object(
  'song', pg_temp.song('selam', '  Selam  '),
  'recordings', jsonb_build_array(pg_temp.rec('r1', 'selam')),
  'timings', jsonb_build_array(pg_temp.timing('r1')))) as id;
select is(pg_temp.approve((select id from new1)), 'selam', 'an approved new song is published');
select is((select status::text from public.songs where id = 'selam'), 'approved', 'as an approved song');
select is((select title from public.songs where id = 'selam'), 'Selam', 'with its title trimmed');
select is(public.get_song('selam') #>> '{song,playOrder}', '["v", "c", "c"]', 'get_song serves its lyrics');
select is(public.get_song('selam') #>> '{recordings,0,fileName}', 'r1.mp3', 'its recording with the file name');
select is(public.get_song('selam') #>> '{timings,0,startsMs}', '[1000, 2000, 3000, 4000]', 'and its timing');
select ok(
  (select synced from public.song_index() where id = 'selam'),
  'it is in the song index as synced');
select is((select song_id::text from public.contributions where id = (select id from new1)), 'selam',
  'the contribution points at its song');

select is(
  pg_temp.approve(pg_temp.add('new_song', jsonb_build_object('song', pg_temp.song('selam')))),
  'selam-2', 'a taken slug gets -2');
select is(
  pg_temp.approve(pg_temp.add('new_song', jsonb_build_object('song', pg_temp.song('selam')))),
  'selam-3', 'then -3');
select public.seed_song(jsonb_build_object('song', pg_temp.song(repeat('a', 120))));
select is(
  pg_temp.approve(pg_temp.add('new_song', jsonb_build_object('song', pg_temp.song(repeat('a', 120))))),
  repeat('a', 118) || '-2', 'a long slug is shortened to fit its suffix');
select is(
  pg_temp.approve(pg_temp.add('new_song', jsonb_build_object(
    'song', pg_temp.song('yt'), 'recordings', jsonb_build_array(pg_temp.rec('r-yt', 'yt', 'youtube'))))),
  'yt', 'a new song with a YouTube recording');
select is(public.get_song('yt') #>> '{recordings,0,youtubeId}', 'dQw4w9WgXcQ', 'serves its video ID');
select is(public.get_song('yt') -> 'timings', '[]', 'and no timing');

-- Corrections. ----------------------------------------------------------------------

create temp table v0 as select pg_temp.version() as v;
select is(
  pg_temp.approve(pg_temp.add('edit_lyrics',
    jsonb_build_object('song', jsonb_set(pg_temp.song('test-song', 'Selam Lezih'), '{sections,0,lines,1,text}', '"b2"')),
    'test-song', pg_temp.version())),
  'test-song', 'an approved correction');
select is(public.get_song('test-song') #>> '{song,title}', 'Selam Lezih', 'replaces the title');
select is(public.get_song('test-song') #>> '{song,sections,0,lines,1,text}', 'b2', 'and the lines');
select ok(pg_temp.version() > (select v from v0), 'and bumps the version');
select is(pg_temp.starts('test-rec'), '{1000,2000,3000,4000}', 'the same number of sung lines keeps the timing');

create temp table v1 as select pg_temp.version() as v;
select pg_temp.approve(pg_temp.add('edit_lyrics',
  jsonb_build_object('song', jsonb_set(pg_temp.song('test-song'), '{playOrder}', '["v", "c", "c", "c"]')),
  'test-song', pg_temp.version() - 1));
select is(pg_temp.starts('test-rec'), null, 'a different number removes it');
select is((select count(*)::int from public.recordings where song_id = 'test-song'), 2, 'the recordings stay');
select is(
  (select count(*)::int from public.play_order where song_id = 'test-song'), 4,
  'the play order is replaced');
select is(
  (select count(*)::int from public.lines where song_id = 'test-song'), 3,
  'the lines are replaced, not added');

-- Recordings and timings (the song now sings 5 lines). ------------------------------

select is(
  pg_temp.approve(pg_temp.add('recording', jsonb_build_object(
    'recordings', jsonb_build_array(pg_temp.rec('r3', 'test-song')),
    'timings', jsonb_build_array(pg_temp.timing('r3', '{1,2,3,4,5}'))), 'test-song')),
  'test-song', 'an approved recording');
select results_eq(
  $$select source::text, file_name, duration_ms from public.recordings where id = 'r3'$$,
  $$values ('local_file', 'r3.mp3', 60000)$$,
  'is added with its file name');
select is(pg_temp.starts('r3'), '{1,2,3,4,5}', 'and its timing');

select pg_temp.approve(pg_temp.add('sync_timing',
  jsonb_build_object('timings', jsonb_build_array(pg_temp.timing('test-rec2', '{10,20,30,40,50}'))), 'test-song'));
select is(pg_temp.starts('test-rec2'), '{10,20,30,40,50}', 'an approved sync adds the timing');
select pg_temp.approve(pg_temp.add('sync_timing',
  jsonb_build_object('timings', jsonb_build_array(pg_temp.timing('test-rec2', '{11,21,31,41,51}'))), 'test-song'));
select is(pg_temp.starts('test-rec2'), '{11,21,31,41,51}', 'a second sync replaces it');

-- Failures leave everything as it was. ---------------------------------------------

-- A sync made for 5 lines, then a correction to 4: approving the sync fails.
create temp table stale as select pg_temp.add('sync_timing',
  jsonb_build_object('timings', jsonb_build_array(pg_temp.timing('r3', '{100,200,300,400,500}'))), 'test-song') as id;
select pg_temp.approve(pg_temp.add('edit_lyrics', jsonb_build_object('song', pg_temp.song('test-song')),
  'test-song', pg_temp.version()));
select throws_ok($$select pg_temp.approve((select id from stale))$$,
  '22023', 'timing_count', 'a sync for a song corrected since then is refused');
select is((select status::text from public.contributions where id = (select id from stale)), 'pending',
  'and stays pending');
select is(pg_temp.starts('r3'), null, 'with the timing the correction removed still gone');

create temp table clash as select pg_temp.add('new_song', jsonb_build_object(
  'song', pg_temp.song('clash'), 'recordings', jsonb_build_array(pg_temp.rec('test-rec', 'clash')))) as id;
select throws_ok($$select pg_temp.approve((select id from clash))$$,
  '22023', 'bad_recording', 'a new song whose recording ID is taken is refused');
select is((select count(*)::int from public.songs where id = 'clash'), 0, 'and nothing is published');
select is((select status::text from public.contributions where id = (select id from clash)), 'pending',
  'it stays pending');

-- Nothing before approval. ----------------------------------------------------------

create temp table hidden as select pg_temp.add('new_song', jsonb_build_object('song', pg_temp.song('hidden'))) as id;
create temp table refused as select pg_temp.add('new_song', jsonb_build_object('song', pg_temp.song('refused'))) as id;
select public.review_contribution((select id from refused), 'rejected', 'Duplicate');
select public.review_contribution(
  pg_temp.add('recording', jsonb_build_object('recordings', jsonb_build_array(pg_temp.rec('r-back', 'test-song'))), 'test-song'),
  'changes_requested', 'Which choir?');
grant select on hidden, refused to anon;
set local role anon;
select is(public.get_song('hidden'), null, 'a pending song is not served');
select is(public.get_song('refused'), null, 'nor a rejected one');
select is_empty($$select id from public.songs where id in ('hidden', 'refused')$$, 'neither is in the catalog');
select is_empty($$select id from public.recordings where id = 'r-back'$$, 'nor a recording sent back');
select is_empty($$select id from public.song_index() where id in ('hidden', 'refused')$$, 'nor the index');
reset role;
select is((select count(*)::int from public.songs where id in ('hidden', 'refused')), 0,
  'not even as drafts');

select * from finish();
rollback;
