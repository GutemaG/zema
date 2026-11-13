-- Fingerprints sent from phones (intent 009, FR-2): with contributions, and
-- shared from libraries.
begin;
create extension if not exists pgtap with schema extensions;

select plan(29);

insert into auth.users (id, email) values
  ('00000000-0000-0000-0000-0000000000a1', 'a@example.com'),
  ('00000000-0000-0000-0000-0000000000b1', 'b@example.com'),
  ('00000000-0000-0000-0000-0000000000d1', 'mod@example.com');
insert into public.user_roles (user_id, role) values
  ('00000000-0000-0000-0000-0000000000d1', 'moderator');

create function pg_temp.as_user(id text) returns void language sql as $$
  select set_config('request.jwt.claims',
    jsonb_build_object('sub', id, 'role', 'authenticated')::text, true)
$$;
create function pg_temp.song(id text) returns jsonb language sql as $$
  select jsonb_build_object('id', id, 'title', id,
    'sections', jsonb_build_array(jsonb_build_object('id', 'v', 'kind', 'verse',
      'lines', jsonb_build_array(jsonb_build_object('text', 'a')))),
    'playOrder', jsonb_build_array('v'))
$$;
create function pg_temp.rec(id text, song text, source text default 'localFile') returns jsonb language sql as $$
  select jsonb_build_object('id', id, 'songId', song, 'source', source, 'durationMs', 60000)
    || case when source = 'youtube' then jsonb_build_object('youtubeId', 'dQw4w9WgXcQ')
       else jsonb_build_object('fileName', id || '.mp3') end
$$;
create function pg_temp.add(kind public.contribution_kind, payload jsonb, song text default null)
returns uuid language sql as $$
  insert into public.contributions (author_id, kind, payload, song_id)
  values ('00000000-0000-0000-0000-0000000000a1', kind, payload, song)
  returning id
$$;
-- Hash i at frame 10 * i + shift, for i in [from, to]; 60 s is 2584 frames.
create function pg_temp.hashes(from_i int, to_i int) returns int[] language sql as $$
  select array_agg(i order by i) from generate_series(from_i, to_i) i
$$;
create function pg_temp.frames(from_i int, to_i int, shift int default 0) returns int[] language sql as $$
  select array_agg(10 * i + shift order by i) from generate_series(from_i, to_i) i
$$;
create function pg_temp.attach(id uuid, frame_count int default 2584) returns void language sql as $$
  select public.attach_fingerprint(id, 1, frame_count, pg_temp.hashes(1, 200), pg_temp.frames(1, 200))
$$;
create function pg_temp.share(rec text, install text, shift int default 0, from_i int default 1,
  to_i int default 200) returns text language sql as $$
  select public.share_fingerprint(rec, 1, 2584, pg_temp.hashes(from_i, to_i),
    pg_temp.frames(from_i, to_i, shift), install)
$$;
create function pg_temp.has_fingerprint(rec text) returns boolean language sql as $$
  select exists (select 1 from public.recording_fingerprints where recording_id = rec)
$$;

select public.seed_song(jsonb_build_object('song', pg_temp.song('test-song'),
  'recordings', jsonb_build_array(pg_temp.rec('lib-1', 'test-song'), pg_temp.rec('lib-2', 'test-song'),
    pg_temp.rec('lib-3', 'test-song'), pg_temp.rec('lib-4', 'test-song'))));
select public.seed_song(jsonb_build_object('song', pg_temp.song('draft-song'),
  'recordings', jsonb_build_array(pg_temp.rec('draft-rec', 'draft-song'))), 'draft');

-- Contributions ---------------------------------------------------------------------

create temp table c as select
  pg_temp.add('new_song', jsonb_build_object('song', pg_temp.song('selam'),
    'recordings', jsonb_build_array(pg_temp.rec('r1', 'selam')))) as approved,
  pg_temp.add('recording', jsonb_build_object(
    'recordings', jsonb_build_array(pg_temp.rec('r2', 'test-song'))), 'test-song') as rejected,
  pg_temp.add('recording', jsonb_build_object(
    'recordings', jsonb_build_array(pg_temp.rec('r3', 'test-song', 'youtube'))), 'test-song') as youtube,
  pg_temp.add('new_song', jsonb_build_object('song', pg_temp.song('plain'))) as no_recording;
grant select on c to authenticated;

set local role authenticated;
select pg_temp.as_user('00000000-0000-0000-0000-0000000000a1');
select lives_ok($$ select pg_temp.attach((select approved from c)) $$,
  'the author attaches a fingerprint to their contribution');
select lives_ok($$ select pg_temp.attach((select approved from c)) $$, 'and again, replacing it');
select lives_ok($$ select pg_temp.attach((select rejected from c)) $$, 'to a recording contribution');
select throws_ok($$ select pg_temp.attach((select youtube from c)) $$, '22023', 'bad_recording',
  'not to a YouTube recording');
select throws_ok($$ select pg_temp.attach((select no_recording from c)) $$, '22023', 'bad_recording',
  'nor without a recording');
select throws_ok($$ select pg_temp.attach((select approved from c), 1000) $$, '22023', 'bad_fingerprint',
  'a fingerprint much shorter than the recording is refused');
select throws_ok($$ select public.attach_fingerprint((select approved from c), 1, 2584,
    pg_temp.hashes(1, 50), pg_temp.frames(1, 50)) $$, '22023', 'bad_fingerprint',
  'so are fewer than 100 hashes');
select throws_ok($$ select public.attach_fingerprint((select approved from c), 1, 2584,
    pg_temp.hashes(1, 200), pg_temp.frames(1, 200, 2000)) $$, '22023', 'bad_fingerprint',
  'and frames past the end');
select throws_ok($$ select public.attach_fingerprint((select approved from c), 1, 2584,
    array[16777216] || pg_temp.hashes(2, 200), pg_temp.frames(1, 200)) $$, '22023', 'bad_fingerprint',
  'and hashes over 24 bits');
select pg_temp.as_user('00000000-0000-0000-0000-0000000000b1');
select throws_ok($$ select pg_temp.attach((select approved from c)) $$, '22023', 'not_editable',
  'another user cannot attach one');
select is((select count(*)::int from public.pending_fingerprints), 0,
  'pending fingerprints are not readable through the API');

select pg_temp.as_user('00000000-0000-0000-0000-0000000000d1');
select public.review_contribution((select approved from c), 'approved');
select public.review_contribution((select rejected from c), 'rejected', 'Not this song');
reset role;
select is((select hash_count from public.recording_fingerprints where recording_id = 'r1'), 200,
  'approving the contribution publishes its fingerprint');
select is((select count(*)::int from public.pending_fingerprints), 0,
  'a reviewed contribution keeps no pending fingerprint');
select ok(not pg_temp.has_fingerprint('r2'), 'a rejected one publishes nothing');

-- Libraries --------------------------------------------------------------------------

set local role anon;
select is(array(select public.missing_fingerprints(1, array['lib-1', 'r1', 'draft-rec', 'nope'])),
  array['lib-1']::public.slug[], 'missing_fingerprints lists approved recordings without one');
select is(pg_temp.share('lib-1', 'install-one'), 'pending', 'a first library fingerprint waits');
select is(pg_temp.share('lib-1', 'install-one'), 'pending', 'the same install again still waits');
select is(pg_temp.share('lib-1', 'install-two', 30), 'pending',
  'another install''s that lines up 30 frames apart does not publish');
select is(pg_temp.share('lib-1', 'install-three', 1, 41, 240), 'published',
  'one that lines up within a frame publishes the first');
reset role;
select is((select hash_count from public.recording_fingerprints where recording_id = 'lib-1'), 200,
  'as the recording''s fingerprint');
select is((select count(*)::int from public.pending_fingerprints where recording_id = 'lib-1'), 0,
  'and the others are dropped');
set local role anon;
select is(pg_temp.share('lib-1', 'install-four'), 'not_needed', 'a fingerprinted recording needs none');
select is(pg_temp.share('draft-rec', 'install-four'), 'not_needed', 'nor does one not in the catalog');
select throws_ok($$ select pg_temp.share('lib-2', 'short') $$, '22023', 'Invalid install ID',
  'the install ID is checked');

select pg_temp.share('lib-2', 'install-one');
select pg_temp.share('lib-3', 'install-one');
select pg_temp.share('lib-3', 'install-two', -4900, 500, 600);
set local role authenticated;
select pg_temp.as_user('00000000-0000-0000-0000-0000000000a1');
select throws_ok($$ select * from public.moderator_fingerprints() $$, '42501', 'not_moderator',
  'only moderators see waiting fingerprints');
select pg_temp.as_user('00000000-0000-0000-0000-0000000000d1');
select is(array(select recording_id || ':' || installs || ':' || hash_count
    from public.moderator_fingerprints()),
  array['lib-2:1:200', 'lib-3:2:200', 'lib-3:2:101'], 'moderators see them oldest first');
select public.review_fingerprint(
  (select id from public.moderator_fingerprints() where recording_id = 'lib-2'), true);
select public.review_fingerprint(
  (select id from public.moderator_fingerprints() where hash_count = 101), false);
select is(array(select recording_id from public.moderator_fingerprints()), array['lib-3'],
  'approving and dropping take them off the list');
reset role;
select ok(pg_temp.has_fingerprint('lib-2'), 'an approved one is published');
select ok(not pg_temp.has_fingerprint('lib-3'), 'a dropped one is not');

select * from finish();
rollback;
