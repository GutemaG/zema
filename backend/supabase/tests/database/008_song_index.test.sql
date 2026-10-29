-- song_index (bolt 022): approved songs only, with synced, version and approval time.
begin;
create extension if not exists pgtap with schema extensions;

select plan(8);

delete from public.songs;
insert into public.songs (id, title, transliteration, artist, album, status) values
  ('a-synced', 'ሀ', 'Ha', 'Artist', 'Album', 'approved'),
  ('b-plain', 'ለ', null, null, null, 'approved'),
  ('c-draft', 'ሐ', null, null, null, 'draft'),
  ('d-rejected', 'መ', null, null, null, 'rejected');
insert into public.recordings (id, song_id, source) values
  ('a-synced', 'a-synced', 'local_file'),
  ('b-plain', 'b-plain', 'local_file');
insert into public.sync_timings (recording_id, starts_ms) values ('a-synced', '{0}');

set local role anon;

select results_eq(
  'select id from public.song_index()',
  array['a-synced', 'b-plain']::text[],
  'only approved songs are listed, by ID'
);
select is(
  (select synced from public.song_index() where id = 'a-synced'), true,
  'a song with a timing is synced'
);
select is(
  (select synced from public.song_index() where id = 'b-plain'), false,
  'a song whose recordings have no timing is not'
);
select is(
  (select (title, transliteration, artist, album)::text from public.song_index()
   where id = 'a-synced'),
  '(ሀ,Ha,Artist,Album)',
  'title, transliteration, artist and album are returned'
);
select ok(
  (select bool_and(approved_at is not null) from public.song_index()),
  'every entry has its approval time'
);

reset role;
create temporary table before as select version from public.songs where id = 'b-plain';
grant select on before to anon;
update public.songs set title = 'ለለ' where id = 'b-plain';
set local role anon;
select cmp_ok(
  (select version from public.song_index() where id = 'b-plain'), '>',
  (select version from before),
  'an edit shows as a higher version'
);

reset role;
update public.songs set status = 'draft' where id = 'b-plain';
set local role anon;
select is(
  (select count(*)::int from public.song_index() where id = 'b-plain'), 0,
  'a song taken back to draft drops out'
);

select ok(
  has_function_privilege('anon', 'public.song_index()', 'execute'),
  'anon may call it'
);

select * from finish();
rollback;
