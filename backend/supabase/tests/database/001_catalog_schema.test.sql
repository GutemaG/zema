-- Catalog schema (bolt 018): tables, RLS on, constraints, cascades, version bumps.
begin;
create extension if not exists pgtap with schema extensions;

-- Reports made against the local backend (emulator checks) would skew the counts.
delete from public.reports;

-- Start from an empty catalog (the seed songs come back on rollback).
delete from public.songs;

select plan(28);

-- Tables -----------------------------------------------------------------------

select tables_are(
  'public',
  array[
    'songs', 'sections', 'lines', 'play_order', 'recordings', 'sync_timings',
    'reports', 'user_roles', 'contributions', 'profiles', 'backups',
    'search_entries', 'search_entry_words', 'search_vocab', 'search_syllable_consonants',
    'recording_fingerprints', 'fingerprint_hashes'
  ],
  'the catalog has exactly the expected tables'
);

select ok(
  (select bool_and(c.relrowsecurity)
   from pg_class c
   join pg_namespace n on n.oid = c.relnamespace
   where n.nspname = 'public' and c.relkind = 'r'),
  'row level security is on for every table'
);

select is(
  (select string_agg(format('%s %s', tablename, cmd), ', ') from pg_policies
   where schemaname = 'public' and cmd <> 'SELECT'),
  'profiles UPDATE',
  'the only write policy is a user renaming their own profile (bolt 029)'
);

-- Fixtures ---------------------------------------------------------------------

insert into public.songs (id, title, artist, status)
values ('selam-lezih-bet', 'ሰላም ለዚህ ቤት', 'Zema Samples', 'draft');
insert into public.sections (song_id, id, kind, position)
values ('selam-lezih-bet', 'v1', 'verse', 0), ('selam-lezih-bet', 'c', 'chorus', 1);
insert into public.lines (song_id, section_id, position, text, transliteration)
values
  ('selam-lezih-bet', 'v1', 0, 'ሰላም ለዚህ ቤት', 'Selam lezih bet'),
  ('selam-lezih-bet', 'c', 0, 'ሃሌ ሉያ', 'Hale luya');
insert into public.play_order (song_id, position, section_id)
values ('selam-lezih-bet', 0, 'v1'), ('selam-lezih-bet', 1, 'c'), ('selam-lezih-bet', 2, 'c');
insert into public.recordings (id, song_id, source, duration_ms)
values ('selam-lezih-bet-sample', 'selam-lezih-bet', 'bundled', 43000);
insert into public.sync_timings (recording_id, starts_ms)
values ('selam-lezih-bet-sample', array[1000, 5000, 9000]);

-- Constraints ------------------------------------------------------------------

select throws_ok(
  $$insert into public.songs (id, title) values ('Not A Slug', 'x')$$,
  '23514', null, 'song IDs must be lowercase slugs'
);
select throws_ok(
  $$insert into public.songs (id, title) values ('blank-title', '  ')$$,
  '23514', null, 'a song needs a title'
);
select throws_ok(
  $$update public.sync_timings set starts_ms = array[1000, 900]
    where recording_id = 'selam-lezih-bet-sample'$$,
  '23514', null, 'timings may not go backwards'
);
select throws_ok(
  $$update public.sync_timings set starts_ms = '{}'
    where recording_id = 'selam-lezih-bet-sample'$$,
  '23514', null, 'timings may not be empty'
);
select throws_ok(
  $$update public.sync_timings set starts_ms = array[-1, 5]
    where recording_id = 'selam-lezih-bet-sample'$$,
  '23514', null, 'timings may not be negative'
);
select lives_ok(
  $$update public.sync_timings set starts_ms = array[1000, 1000, 9000]
    where recording_id = 'selam-lezih-bet-sample'$$,
  'two lines may start together'
);
select throws_ok(
  $$insert into public.reports (song_id, reason, note, install_hash)
    values ('selam-lezih-bet', 'other', repeat('x', 501), 'h')$$,
  '23514', null, 'report notes are at most 500 characters'
);
select throws_ok(
  $$insert into public.play_order (song_id, position, section_id)
    values ('selam-lezih-bet', 3, 'missing')$$,
  '23503', null, 'play order may only name existing sections'
);
select throws_ok(
  $$insert into public.recordings (id, song_id, source, duration_ms)
    values ('bad-duration', 'selam-lezih-bet', 'bundled', 0)$$,
  '23514', null, 'durations are positive'
);

-- Version bumps ----------------------------------------------------------------

create temporary table v as select version from public.songs where id = 'selam-lezih-bet';
-- The last update above changed timings, so start from the current value.

update public.lines set text = 'ሰላም ለዚህ ቤት ይሁን'
  where song_id = 'selam-lezih-bet' and section_id = 'v1' and position = 0;
select ok(
  (select version from public.songs where id = 'selam-lezih-bet') > (select version from v),
  'editing a line bumps the song version'
);

update v set version = (select version from public.songs where id = 'selam-lezih-bet');
insert into public.recordings (id, song_id, source) values ('selam-lezih-bet-live', 'selam-lezih-bet', 'youtube');
select ok(
  (select version from public.songs where id = 'selam-lezih-bet') > (select version from v),
  'adding a recording bumps the version'
);

update v set version = (select version from public.songs where id = 'selam-lezih-bet');
insert into public.sync_timings (recording_id, starts_ms) values ('selam-lezih-bet-live', array[0, 10]);
select ok(
  (select version from public.songs where id = 'selam-lezih-bet') > (select version from v),
  'adding timings bumps the version'
);

update v set version = (select version from public.songs where id = 'selam-lezih-bet');
delete from public.play_order where song_id = 'selam-lezih-bet' and position = 2;
select ok(
  (select version from public.songs where id = 'selam-lezih-bet') > (select version from v),
  'changing the play order bumps the version'
);

update v set version = (select version from public.songs where id = 'selam-lezih-bet');
update public.songs set album = 'ምስጋና' where id = 'selam-lezih-bet';
select is(
  (select version from public.songs where id = 'selam-lezih-bet'),
  (select version + 1 from v),
  'editing the album bumps the version by exactly one'
);

update v set version = (select version from public.songs where id = 'selam-lezih-bet');
update public.songs set artist = 'Zema', version = version + 5 where id = 'selam-lezih-bet';
select is(
  (select version from public.songs where id = 'selam-lezih-bet'),
  (select version + 5 from v),
  'a version set together with a text change is kept as given'
);

update v set version = (select version from public.songs where id = 'selam-lezih-bet');
update public.songs set status = 'approved' where id = 'selam-lezih-bet';
select is(
  (select version from public.songs where id = 'selam-lezih-bet'),
  (select version from v),
  'approving does not change the version'
);
select isnt(
  (select approved_at from public.songs where id = 'selam-lezih-bet'),
  null,
  'approving records when'
);

insert into public.songs (id, title, status) values ('born-approved', 'x', 'approved');
select isnt(
  (select approved_at from public.songs where id = 'born-approved'),
  null,
  'a song inserted as approved records when'
);
select is(
  (select version from public.songs where id = 'born-approved'),
  1,
  'a new song starts at version 1'
);

-- Cascades ---------------------------------------------------------------------

insert into public.reports (song_id, recording_id, reason, install_hash)
values ('selam-lezih-bet', 'selam-lezih-bet-sample', 'wrong_words', 'h');

delete from public.songs where id = 'selam-lezih-bet';

select is((select count(*)::int from public.sections where song_id = 'selam-lezih-bet'), 0,
  'deleting a song deletes its sections');
select is((select count(*)::int from public.lines where song_id = 'selam-lezih-bet'), 0,
  'and its lines');
select is((select count(*)::int from public.play_order where song_id = 'selam-lezih-bet'), 0,
  'and its play order');
select is((select count(*)::int from public.recordings where song_id = 'selam-lezih-bet'), 0,
  'and its recordings');
select is((select count(*)::int from public.sync_timings
           where recording_id like 'selam-lezih-bet%'), 0,
  'and their timings');
select is((select count(*)::int from public.reports where song_id is null and recording_id is null), 1,
  'reports about it stay, with the references cleared');

select * from finish();
rollback;
