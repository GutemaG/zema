-- Times search_songs on a catalog of 5,000 synthetic songs (30 lines each,
-- words from a pool of 20,000 made-up Ethiopic words), inside a transaction
-- that is rolled back. Not part of `supabase test db`.
--
-- Run (about a minute):
--   docker exec -i supabase_db_zema psql -U postgres -f - < backend/bench/search_bench.sql
\timing off
begin;
set client_min_messages = warning;

create temporary table pool (i integer primary key, word text not null);
insert into pool
select i, (
  select string_agg(chr(4608 + 8 * (floor(random() * 42))::int + (floor(random() * 7))::int), '')
  from generate_series(1, 2 + (i % 3))
) as word
from generate_series(1, 20000) as i;

\echo 'Loading 5,000 songs and 150,000 lines...'
\timing on
insert into public.songs (id, title, artist, status)
select 'bench-' || s,
  (select string_agg(word, ' ') from pool where i in (1 + (s * 7) % 20000, 1 + (s * 13) % 20000)),
  'Bench Artist ' || (s % 200),
  'approved'
from generate_series(1, 5000) as s;

insert into public.sections (song_id, id, kind, position)
select 'bench-' || s, 'v1', 'verse', 0 from generate_series(1, 5000) as s;

insert into public.lines (song_id, section_id, position, text)
select 'bench-' || s, 'v1', l,
  (select string_agg(word, ' ') from pool
   where i in (1 + (s * 31 + l * 17) % 20000, 1 + (s * 37 + l * 19) % 20000,
               1 + (s * 41 + l * 23) % 20000, 1 + (s * 43 + l * 29) % 20000,
               1 + (s * 47 + l * 31) % 20000))
from generate_series(1, 5000) as s, generate_series(0, 29) as l;
\timing off

select count(*) as vocab_words from public.search_vocab;
select count(*) as entries from public.search_entries;

analyze public.search_vocab;
analyze public.search_entry_words;
analyze public.search_entries;

select (select word from pool where i = 42) as q1,
  (select word from pool where i = 4242) || ' ' || (select word from pool where i = 777) as q2,
  (select word from pool where i = 9000) as q3
\gset

set role anon;
\echo 'Searches (each run twice; the second time is warm):'
\timing on
select count(*) from public.search_songs(:'q1');
select count(*) from public.search_songs(:'q1');
select count(*) from public.search_songs(:'q3');
select count(*) from public.search_songs(:'q3');
select count(*) from public.search_songs('kidist');
select count(*) from public.search_songs('kidist');
select count(*) from public.search_songs('selam bet');
select count(*) from public.search_songs('selam bet');
select count(*) from public.search_songs(:'q2');
select count(*) from public.search_songs(:'q2');
\timing off
reset role;
rollback;
