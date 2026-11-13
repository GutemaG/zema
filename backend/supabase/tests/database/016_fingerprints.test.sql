-- Fingerprints and identify_audio (intent 009, FR-2 and FR-3).
begin;
create extension if not exists pgtap with schema extensions;

select plan(18);

create function pg_temp.song(id text, status public.song_status default 'approved') returns void language sql as $$
  select public.seed_song(jsonb_build_object(
    'song', jsonb_build_object('id', id, 'title', id,
      'sections', jsonb_build_array(jsonb_build_object('id', 'v', 'kind', 'verse',
        'lines', jsonb_build_array(jsonb_build_object('text', 'a'))))),
    'recordings', jsonb_build_array(jsonb_build_object('id', id, 'songId', id,
      'source', 'localFile', 'durationMs', 60000))), status);
$$;

-- Hash i at frame 10 * i, for i in [from, to].
create function pg_temp.hashes(from_i int, to_i int) returns int[] language sql as $$
  select array_agg(i order by i) from generate_series(from_i, to_i) i
$$;
create function pg_temp.frames(from_i int, to_i int, shift int default 0) returns int[] language sql as $$
  select array_agg(10 * i - shift order by i) from generate_series(from_i, to_i) i
$$;

select pg_temp.song('song-a');
select pg_temp.song('song-draft', 'draft');
select pg_temp.song('song-chorus');
select public.put_fingerprint('song-a', 1, 1100, pg_temp.hashes(1, 100), pg_temp.frames(1, 100));
select public.put_fingerprint('song-draft', 1, 1100, pg_temp.hashes(1, 100), pg_temp.frames(1, 100));
-- The same 20 hashes twice, 1000 frames apart, as a chorus sung again.
select public.put_fingerprint('song-chorus', 1, 2300,
  pg_temp.hashes(201, 220) || pg_temp.hashes(201, 220),
  pg_temp.frames(201, 220) || pg_temp.frames(201, 220, -1000));

select is((select hash_count from public.recording_fingerprints where recording_id = 'song-a'), 100,
  'the fingerprint is stored with its hash count');
select public.put_fingerprint('song-a', 1, 1100, pg_temp.hashes(1, 100), pg_temp.frames(1, 100));
select is((select count(*)::int from public.fingerprint_hashes where recording_id = 'song-a'), 100,
  'putting it again replaces it');

-- An excerpt of hashes 40..69 that starts 395 frames into the recording.
create temporary table found as
  select * from public.identify_audio(1, pg_temp.hashes(40, 69), pg_temp.frames(40, 69, 395));
select is((select count(*)::int from found), 1, 'one recording matches; the draft song is not searched');
select is((select recording_id::text from found), 'song-a', 'it is the right recording');
select is((select song_id::text from found), 'song-a', 'with its song');
select is((select shift from found), 395, 'the excerpt starts at frame 395');
select is((select score from found), 30, 'every hash lined up');
select is((select runner_up from found), 0, 'nowhere else');
select is((select frame_count from found), 1100, 'with the recording''s length');

select is(
  (select score from public.identify_audio(1, pg_temp.hashes(40, 69),
    (select array_agg(10 * i - 395 + (i % 2)) from generate_series(40, 69) i))),
  30, 'peaks a frame apart still count');

select is_empty(
  $$select * from public.identify_audio(1, pg_temp.hashes(40, 50), pg_temp.frames(40, 50))$$,
  'eleven hashes are not enough');
select is_empty(
  $$select * from public.identify_audio(2, pg_temp.hashes(40, 69), pg_temp.frames(40, 69))$$,
  'fingerprints of another version are not compared');

select is(
  (select query from public.identify_audio(1,
    pg_temp.hashes(500, 529) || pg_temp.hashes(40, 69),
    pg_temp.frames(1, 30) || pg_temp.frames(40, 69),
    array_fill(0, array[30]) || array_fill(1, array[30]))),
  1, 'of several speeds, the query that lined up is returned');

select results_eq(
  $$select score, runner_up from public.identify_audio(1, pg_temp.hashes(201, 220), pg_temp.frames(201, 220))$$,
  $$values (20, 20)$$,
  'a repeated chorus scores as well elsewhere');

select throws_ok(
  $$select * from public.identify_audio(1, array[1, 2], array[1])$$,
  '22023', null, 'hashes and frames must line up');

set local role anon;
select lives_ok(
  $$select * from public.identify_audio(1, array[1], array[1])$$,
  'listeners may search');
select throws_ok(
  $$select public.put_fingerprint('song-a', 1, 10, array[1], array[1])$$,
  '42501', null, 'but not store fingerprints');
select is_empty($$select * from public.fingerprint_hashes$$, 'or read the hashes');

select * from finish();
rollback;
