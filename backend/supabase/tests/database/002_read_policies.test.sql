-- Read rules (bolt 019): anonymous users see approved songs only, write nothing.
begin;
create extension if not exists pgtap with schema extensions;

-- Start from an empty catalog (the seed songs come back on rollback).
delete from public.songs;

select plan(31);

-- Fixtures, as the table owner: one song per status, each with every part.
insert into public.songs (id, title, status) values
  ('open-song', 'Open', 'approved'),
  ('draft-song', 'Draft', 'draft'),
  ('gone-song', 'Gone', 'rejected');
insert into public.sections (song_id, id, kind, position)
select id, 'v1', 'verse', 0 from public.songs;
insert into public.lines (song_id, section_id, position, text)
select id, 'v1', 0, 'line' from public.songs;
insert into public.play_order (song_id, position, section_id)
select id, 0, 'v1' from public.songs;
insert into public.recordings (id, song_id, source)
select id || '-rec', id, 'bundled' from public.songs;
insert into public.sync_timings (recording_id, starts_ms)
select id, array[0] from public.recordings;
insert into public.reports (song_id, reason, install_hash) values ('open-song', 'other', 'h');
insert into public.contributions (kind, payload) values ('new_song', '{}');

-- As an anonymous listener ------------------------------------------------------
set local role anon;

select results_eq('select id::text from public.songs', array['open-song'],
  'anon sees approved songs only');
select results_eq('select song_id::text from public.sections', array['open-song'],
  'and their sections');
select results_eq('select song_id::text from public.lines', array['open-song'],
  'and their lines');
select results_eq('select song_id::text from public.play_order', array['open-song'],
  'and their play order');
select results_eq('select id::text from public.recordings', array['open-song-rec'],
  'and their recordings');
select results_eq('select recording_id::text from public.sync_timings', array['open-song-rec'],
  'and their timings');
select is_empty('select * from public.reports', 'anon reads no reports');
select is_empty('select * from public.contributions', 'anon reads no contributions');
select is_empty('select * from public.user_roles', 'anon reads no roles');

-- Writes: refused by privileges (42501) on every table.
select throws_ok($$insert into public.songs (id, title, status) values ('mine', 'x', 'approved')$$,
  '42501', null, 'anon cannot insert songs');
select throws_ok($$update public.songs set title = 'x'$$, '42501', null, 'anon cannot update songs');
select throws_ok($$delete from public.songs$$, '42501', null, 'anon cannot delete songs');
select throws_ok($$insert into public.sections (song_id, id, kind, position) values ('open-song', 'x', 'verse', 9)$$,
  '42501', null, 'anon cannot insert sections');
select throws_ok($$update public.lines set text = 'x'$$, '42501', null, 'anon cannot update lines');
select throws_ok($$delete from public.play_order$$, '42501', null, 'anon cannot delete play order');
select throws_ok($$insert into public.recordings (id, song_id, source) values ('r', 'open-song', 'bundled')$$,
  '42501', null, 'anon cannot insert recordings');
select throws_ok($$update public.sync_timings set starts_ms = array[1]$$, '42501', null,
  'anon cannot update timings');
select throws_ok($$insert into public.reports (song_id, reason, install_hash) values ('open-song', 'other', 'x')$$,
  '42501', null, 'anon cannot insert reports directly');
select throws_ok($$insert into public.contributions (kind, payload) values ('new_song', '{}')$$,
  '42501', null, 'anon cannot insert contributions');
select throws_ok($$delete from public.user_roles$$, '42501', null, 'anon cannot delete roles');

-- As a signed-in user (no roles yet): the same --------------------------------
reset role;
set local role authenticated;

select results_eq('select id::text from public.songs', array['open-song'],
  'signed-in users also see approved songs only');
select is_empty('select * from public.reports', 'and no reports');
select throws_ok($$update public.songs set title = 'x'$$, '42501', null,
  'and cannot update songs');
select throws_ok($$insert into public.user_roles (user_id, role) values (gen_random_uuid(), 'admin')$$,
  '42501', null, 'and cannot give themselves a role');

-- Status changes take effect at once -------------------------------------------
reset role;
update public.songs set status = 'draft' where id = 'open-song';
set local role anon;
select is_empty('select * from public.songs', 'a song moved back to draft disappears');
select is_empty('select * from public.lines', 'with its lines');
select is_empty('select * from public.sync_timings', 'and timings');

reset role;
update public.songs set status = 'approved' where id = 'draft-song';
set local role anon;
select results_eq('select id::text from public.songs', array['draft-song'],
  'an approved draft appears');
select results_eq('select recording_id::text from public.sync_timings', array['draft-song-rec'],
  'with its timings');

-- Policies: read-only ------------------------------------------------------------
reset role;
select is(
  (select count(*)::int from pg_policies where schemaname = 'public' and cmd = 'SELECT'),
  6,
  'six read policies: songs and their five kinds of parts'
);
select is(
  (select count(*)::int from pg_policies
   where schemaname = 'public' and tablename in ('reports', 'contributions', 'user_roles')),
  0,
  'no policy opens reports, contributions or roles'
);

select * from finish();
rollback;
