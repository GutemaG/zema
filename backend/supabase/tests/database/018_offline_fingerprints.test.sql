-- The offline index on phones (intent 009, FR-4).
begin;
create extension if not exists pgtap with schema extensions;

select plan(9);

create function pg_temp.song(id text, status public.song_status default 'approved') returns void language sql as $$
  select public.seed_song(jsonb_build_object(
    'song', jsonb_build_object('id', id, 'title', id,
      'sections', jsonb_build_array(jsonb_build_object('id', 'v', 'kind', 'verse',
        'lines', jsonb_build_array(jsonb_build_object('text', 'a'))))),
    'recordings', jsonb_build_array(jsonb_build_object('id', id, 'songId', id,
      'source', 'localFile', 'durationMs', 60000))), status);
$$;
create function pg_temp.hashes(from_i int, to_i int) returns int[] language sql as $$
  select array_agg(i order by i) from generate_series(from_i, to_i) i
$$;
create function pg_temp.frames(from_i int, to_i int) returns int[] language sql as $$
  select array_agg(10 * i order by i) from generate_series(from_i, to_i) i
$$;

select pg_temp.song('song-a');
select pg_temp.song('song-b');
select pg_temp.song('song-draft', 'draft');
select public.put_fingerprint('song-a', 1, 2584, pg_temp.hashes(1, 100), pg_temp.frames(1, 100));
select public.put_fingerprint('song-b', 1, 2584, pg_temp.hashes(201, 300), pg_temp.frames(201, 300));
select public.put_fingerprint('song-draft', 1, 2584, pg_temp.hashes(1, 100), pg_temp.frames(1, 100));

select is((select revision from public.recording_fingerprints where recording_id = 'song-a'), 1,
  'a new fingerprint is revision 1');
select public.put_fingerprint('song-a', 1, 2584, pg_temp.hashes(1, 100), pg_temp.frames(1, 100));
select is((select revision from public.recording_fingerprints where recording_id = 'song-a'), 2,
  'replacing it raises the revision');
select is((select count(*)::int from public.fingerprint_hashes where recording_id = 'song-a'), 100,
  'with its hashes replaced, not added');

set local role anon;
select is(array(select recording_id || ':' || revision || ':' || identified
    from public.offline_fingerprints(1)),
  array['song-a:2:0', 'song-b:1:0'], 'offline_fingerprints lists approved songs only');
select is((select count(*)::int from public.identify_audio(1, pg_temp.hashes(201, 240),
    pg_temp.frames(201, 240), 'install-offline')), 1, 'Listen finds song-b');
select is(array(select recording_id || ':' || identified from public.offline_fingerprints(1)),
  array['song-b:1', 'song-a:0'], 'which now comes first, identified once');
select is((select hashes[1:3] from public.get_fingerprints(1, array['song-b'])), array[201, 202, 203],
  'get_fingerprints serves the hashes');
select is((select frames[1:3] from public.get_fingerprints(1, array['song-b'])), array[2010, 2020, 2030],
  'with their frames, in frame order');
select is((select count(*)::int from public.get_fingerprints(1, array['song-a', 'song-draft', 'nope'])), 1,
  'and nothing for a draft or unknown recording');

select * from finish();
rollback;
