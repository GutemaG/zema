-- Search index upkeep (bolt 020): entries follow edits; search_songs limits,
-- hides drafts and is the only way in.
begin;
create extension if not exists pgtap with schema extensions;

-- Start from an empty catalog (the seed songs come back on rollback).
delete from public.songs;

select plan(14);

insert into public.songs (id, title, transliteration, status)
values ('selam', 'ሰላም', 'Selam', 'approved');
insert into public.sections (song_id, id, kind, position) values ('selam', 'v1', 'verse', 0);
insert into public.lines (song_id, section_id, position, text)
values ('selam', 'v1', 0, 'ፍቅር ይግባ'), ('selam', 'v1', 1, 'ተስፋ ይሁን');

create function pg_temp.found(q text) returns text[] language sql as $$
  select coalesce(array_agg(song_id || ':' || coalesce(line_text, '-') order by score desc, song_id), '{}')
  from public.search_songs(q)
$$;

select is(pg_temp.found('fikir'), array['selam:ፍቅር ይግባ'], 'a line is found');

update public.lines set text = 'ብርሃን ይግባ' where song_id = 'selam' and position = 0;
select is(pg_temp.found('fikir'), '{}'::text[], 'an edited line no longer matches its old text');
select is(pg_temp.found('birhan'), array['selam:ብርሃን ይግባ'], 'and matches its new text');

delete from public.lines where song_id = 'selam' and position = 1;
select is(pg_temp.found('tesfa'), '{}'::text[], 'a deleted line is gone from search');

update public.songs set title = 'ሰላም ለኪ', transliteration = 'Selam Leki' where id = 'selam';
select is(pg_temp.found('leki'), array['selam:-'], 'a renamed title is searchable');

update public.songs set status = 'draft' where id = 'selam';
select is(pg_temp.found('leki'), '{}'::text[], 'a draft song is not found');
update public.songs set status = 'approved' where id = 'selam';

insert into public.songs (id, title, status)
select 'many-' || i, 'Tesfa ' || i, 'approved' from generate_series(1, 30) i;
select is((select count(*)::int from public.search_songs('tesfa')), 20, '20 results by default');
select is((select count(*)::int from public.search_songs('tesfa', 5)), 5, 'max_results limits them');
select is((select count(*)::int from public.search_songs('tesfa', -1)), 0, 'a negative limit gives none');

delete from public.songs where id = 'selam';
select is(
  (select count(*)::int from public.search_entries where song_id = 'selam'), 0,
  'a deleted song leaves no entries'
);

set local role anon;
select is((select count(*)::int from public.search_songs('tesfa 7')), 1, 'anon can search');
select is_empty('select * from public.search_entries', 'anon cannot read the entries');
select is_empty('select * from public.search_vocab', 'or the vocabulary');
select throws_ok($$insert into public.search_vocab values ('x', 'x')$$, '42501', null,
  'or write them');

select * from finish();
rollback;
