-- Track prints (intent 013): storing, matching and sharing whole-file prints.
begin;
create extension if not exists pgtap with schema extensions;

select plan(40);

insert into auth.users (id, email) values
  ('00000000-0000-0000-0000-0000000000a1', 'a@example.com'),
  ('00000000-0000-0000-0000-0000000000d1', 'mod@example.com');
insert into public.user_roles (user_id, role) values
  ('00000000-0000-0000-0000-0000000000d1', 'moderator');

create function pg_temp.as_user(id text) returns void language sql as $$
  select set_config('request.jwt.claims',
    jsonb_build_object('sub', id, 'role', 'authenticated')::text, true)
$$;
create function pg_temp.song(id text, status public.song_status default 'approved')
returns void language sql as $$
  select public.seed_song(jsonb_build_object(
    'song', jsonb_build_object('id', id, 'title', id || ' title',
      'sections', jsonb_build_array(jsonb_build_object('id', 'v', 'kind', 'verse',
        'lines', jsonb_build_array(jsonb_build_object('text', 'a')))),
      'playOrder', jsonb_build_array('v')),
    'recordings', jsonb_build_array(jsonb_build_object('id', id || '-rec', 'songId', id,
      'source', 'localFile', 'fileName', id || '.mp3', 'durationMs', 200000))), status)
$$;
-- 2,000 random values (92 s), the same for the same seed.
create function pg_temp.print(seed float) returns int[] language sql as $$
  select setseed(seed);
  select array_agg((floor(random() * 4294967296) - 2147483648)::bigint::int order by i)
  from generate_series(1, 2000) i
$$;
-- [p] with each bit flipped at chance [flip], as a re-encode does.
create function pg_temp.copy(p int[], flip float) returns int[] language sql as $$
  select array_agg(v # (
    select coalesce(sum(1::bigint << b), 0) - case when bool_or(b = 31) then 4294967296 else 0 end
    from generate_series(0, 31) b where random() < flip and t.i > 0
  )::int order by i)
  from unnest(p) with ordinality as t(v, i)
$$;
create function pg_temp.share(song text, p int[], install text, duration int default 200000)
returns text language sql as $$
  select public.share_track_print(song, 1, p, duration, install)
$$;
create function pg_temp.matched(p int[], install text default 'install-m')
returns text language sql as $$
  select string_agg(m.song_id, ',' order by m.bits) from public.match_track(1, p, 200000, install) m
$$;
create function pg_temp.status(song text) returns text language sql security definer as $$
  select coalesce(string_agg(status, ',' order by status), 'none')
  from public.track_prints where song_id = song
$$;

create function pg_temp.conflicts(song text) returns text language sql security definer as $$
  select string_agg(conflict_song_id, ',') from public.track_prints where song_id = song
$$;

select pg_temp.song('song-a');
select pg_temp.song('song-b');
select pg_temp.song('song-c');
select pg_temp.song('draft', 'draft');
create temp table p as select
  pg_temp.print(0.1) as a, pg_temp.print(0.2) as b, pg_temp.print(0.3) as c,
  pg_temp.print(0.4) as other, pg_temp.print(0.5) as draft;
grant select on p to anon, authenticated;

-- Comparing --------------------------------------------------------------------

select is((public.track_print_distance((select a from p), (select a from p))).bits, 0::numeric,
  'a print is 0 apart from itself');
select cmp_ok((public.track_print_distance((select a from p),
    pg_temp.copy((select a from p), 0.15))).bits, '<', 0.2,
  'a copy with 15 % of its bits flipped is about 15 % apart');
select cmp_ok(public.track_print_bits((select a from p), (select b from p), 0), '>', 0.4,
  'unrelated prints are about half apart');
select is((public.track_print_distance((select a from p), (select b from p))).bits, null,
  'and share no keys to line up by');
select is((select d.shift from public.track_print_distance((select a from p), (select a[6:] from p)) d),
  -5, 'a print cut by 5 values lines up 5 values earlier');
select is((public.track_print_distance((select a from p), (select a[1:500] from p))).bits, null,
  'under 30 s of overlap is not compared');

-- Seed tool and lookups ----------------------------------------------------------

select is(public.put_track_print('song-a', 1, (select a from p), 200000), 'published',
  'the seed tool publishes a print');
select is(public.put_track_print('song-a', 1, pg_temp.copy((select a from p), 0.1), 200000),
  'not_needed', 'not a second copy of the same recording');
select is(public.put_track_print('draft', 1, (select draft from p), 200000), 'published',
  'a draft song''s print is stored too');
select cmp_ok((select count(*) from public.track_print_keys k
    join public.track_prints t on t.id = k.print_id where t.song_id = 'song-a'), '>', 100::bigint,
  'with every 16th value''s key');
select throws_ok($$ select public.put_track_print('song-a', 1, (select a[1:100] from p), 200000) $$,
  '22023', 'bad_print', 'too short a print is refused');

set local role anon;
select throws_ok($$ select public.put_track_print('song-b', 1, (select b from p), 200000) $$,
  '42501', null, 'listeners can''t publish prints');
select is_empty($$ select * from public.track_prints $$, 'nor read the prints');
select is(pg_temp.matched(pg_temp.copy((select a from p), 0.15)), 'song-a',
  'a re-encoded copy finds its song');
select is(pg_temp.matched((select a[20:] from p)), 'song-a',
  'and a copy with its start cut');
select is(pg_temp.matched((select other from p)), null, 'other audio finds nothing');
select is(pg_temp.matched((select draft from p)), null, 'nor does a draft song');
select throws_ok($$ select pg_temp.matched((select a from p), 'short') $$, '22023',
  'Invalid install ID', 'an install ID is needed');
select throws_ok($$ select * from public.match_track(1, (select a from p), 1000, 'install-m') $$,
  '22023', 'bad_print', 'and a file at least 30 s long');

-- Sharing ----------------------------------------------------------------------

select is(pg_temp.share('song-b', (select b from p), 'install-1'), 'pending',
  'a first print of a song waits');
select is(pg_temp.share('song-b', (select b from p), 'install-1'), 'pending',
  'the same install again');
select is(pg_temp.status('song-b'), 'pending', 'replaces its print');
select is(pg_temp.matched((select b from p)), null, 'a pending print isn''t found');
select is(pg_temp.share('song-b', pg_temp.copy((select b from p), 0.12), 'install-2'), 'published',
  'a second install''s matching print publishes it');
select is(pg_temp.status('song-b'), 'published', 'as one print, the other dropped');
select is(pg_temp.matched((select b from p)), 'song-b', 'and lookups find it');
select is(pg_temp.share('song-b', (select b from p), 'install-3'), 'not_needed',
  'a third copy is not needed');
select is(pg_temp.share('song-c', pg_temp.copy((select a from p), 0.1), 'install-1'), 'pending',
  'a print matching another song''s waits');
select is(pg_temp.share('song-c', pg_temp.copy((select a from p), 0.1), 'install-2'), 'pending',
  'even when a second install agrees');
select is(pg_temp.conflicts('song-c'), 'song-a,song-a',
  'both are marked with the song they matched');
select is(pg_temp.share('draft', (select c from p), 'install-1'), 'not_needed',
  'a draft song needs none');
select throws_ok($$ select pg_temp.share('song-b', (select c from p), 'install-1', 100000) $$,
  '22023', 'bad_print', 'a file much shorter than the song''s recordings is refused');

reset role;
do $$
begin
  for i in 1..30 loop
    perform pg_temp.share('draft', (select c from p), 'install-busy');
  end loop;
end
$$;
select throws_ok($$ select pg_temp.share('draft', (select c from p), 'install-busy') $$,
  'PT429', 'too_many_today', 'at most 30 shares a day per install');
do $$
begin
  for i in 1..300 loop
    perform pg_temp.matched((select other from p), 'install-busy');
  end loop;
end
$$;
select throws_ok($$ select pg_temp.matched((select other from p), 'install-busy') $$,
  'PT429', 'too_many_today', 'at most 300 lookups a day per install');

-- Moderators -------------------------------------------------------------------

set local role authenticated;
select pg_temp.as_user('00000000-0000-0000-0000-0000000000a1');
select throws_ok($$ select * from public.moderator_track_prints() $$, '42501', 'not_moderator',
  'listeners can''t list waiting prints');
select pg_temp.as_user('00000000-0000-0000-0000-0000000000d1');
select is((select string_agg(song_id || ':' || coalesce(conflict_song_title, '-') || ':' || installs,
    ' ' order by id) from public.moderator_track_prints()),
  'song-c:song-a title:2 song-c:song-a title:2', 'moderators see waiting prints and conflicts');
select lives_ok($$ select public.review_track_print(
    (select min(id) from public.moderator_track_prints()), true) $$,
  'a moderator publishes one');
select is(pg_temp.status('song-c'), 'published', 'its matching twin is dropped');
reset role;
insert into public.track_prints (song_id, version, print, duration_ms, install_key)
values ('song-b', 1, (select c from p), 200000, 'x');
set local role authenticated;
select lives_ok($$ select public.review_track_print(
    (select max(id) from public.moderator_track_prints()), false) $$,
  'or drops one');
select throws_ok($$ select public.review_track_print(0, true) $$, '22023', 'unknown_print',
  'an unknown print');

select * from finish();
rollback;
