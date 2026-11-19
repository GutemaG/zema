-- Moderation for the admin website (bolt 054): reports for moderators, and
-- hiding and restoring songs.
begin;
create extension if not exists pgtap with schema extensions;

select plan(32);

insert into auth.users (id, email, raw_user_meta_data) values
  ('00000000-0000-0000-0000-0000000000a1', 'a@example.com', '{}'),
  ('00000000-0000-0000-0000-0000000000d1', 'mod@example.com', '{}');
insert into public.user_roles (user_id, role) values
  ('00000000-0000-0000-0000-0000000000d1', 'moderator');

create function pg_temp.song(id text, title text, artist text default null)
returns jsonb language sql as $$
  select jsonb_build_object('song', jsonb_build_object(
    'id', id, 'title', title, 'artist', artist,
    'sections', jsonb_build_array(jsonb_build_object('id', 'v', 'kind', 'verse',
      'lines', jsonb_build_array(jsonb_build_object('text', 'a'),
        jsonb_build_object('text', 'b')))),
    'playOrder', jsonb_build_array('v')))
$$;
select public.seed_song(pg_temp.song('selam', 'Selam', 'Tewodros'));
select public.seed_song(pg_temp.song('fikir', 'Fikir'));
select public.seed_song(pg_temp.song('draft-song', 'Selam draft'), 'draft');
update public.songs set approved_at = '2026-01-01' where id = 'selam';

insert into public.reports (id, song_id, reason, note, install_hash, status, created_at) values
  ('00000000-0000-0000-0000-000000000001', 'selam', 'wrong_words', 'line 2', 'h', 'open', now() - interval '2 hours'),
  ('00000000-0000-0000-0000-000000000002', 'fikir', 'wrong_timing', null, 'h', 'open', now() - interval '1 hour'),
  ('00000000-0000-0000-0000-000000000003', 'selam', 'other', null, 'h', 'dismissed', now());

create function pg_temp.act_as(user_id text) returns void language sql as $$
  select set_config('request.jwt.claims',
    json_build_object('sub', user_id, 'role', 'authenticated')::text, true)
$$;

-- Only moderators. -------------------------------------------------------------------

set local role authenticated;
select pg_temp.act_as('00000000-0000-0000-0000-0000000000a1');
select throws_ok('select * from public.moderator_reports()', '42501', 'not_moderator',
  'a user cannot read reports');
select throws_ok($$select public.resolve_report('00000000-0000-0000-0000-000000000001', 'resolved')$$,
  '42501', 'not_moderator', 'or resolve one');
select throws_ok('select * from public.moderator_songs()', '42501', 'not_moderator',
  'or list songs');
select throws_ok($$select public.set_song_hidden('selam', true)$$, '42501', 'not_moderator',
  'or hide one');
select throws_ok($$select public.moderator_song('selam')$$, '42501', 'not_moderator',
  'or read a song through it');
set local role anon;
select throws_ok('select * from public.moderator_reports()', '42501', null, 'anon cannot call it');
select throws_ok($$select public.set_song_hidden('selam', true)$$, '42501', null,
  'or hide a song');

-- Reports. ---------------------------------------------------------------------------

set local role authenticated;
select pg_temp.act_as('00000000-0000-0000-0000-0000000000d1');
select results_eq(
  'select id::text from public.moderator_reports()',
  $$values ('00000000-0000-0000-0000-000000000002'), ('00000000-0000-0000-0000-000000000001')$$,
  'open reports, newest first');
select results_eq(
  $$select song_title, reason::text, note from public.moderator_reports() where song_id = 'selam'$$,
  $$values ('Selam', 'wrong_words', 'line 2')$$,
  'with the song title, reason and note');
select is((select count(*)::integer from public.moderator_reports(null)), 3,
  'null: every status');
select is((select count(*)::integer from public.moderator_reports('open', 1, 1)), 1,
  'paged');
select unalike(pg_get_function_result('public.moderator_reports'::regproc), '%install%',
  'the install hash is not returned');

select lives_ok($$select public.resolve_report('00000000-0000-0000-0000-000000000001', 'resolved')$$,
  'a moderator resolves a report');
select is((select status::text from public.moderator_reports(null)
  where id = '00000000-0000-0000-0000-000000000001'), 'resolved', 'it is resolved');
select is((select count(*)::integer from public.moderator_reports()), 1,
  'and left the open list');
select throws_ok($$select public.resolve_report('00000000-0000-0000-0000-000000000002', 'open')$$,
  '22023', 'bad_status', 'reopening is refused');
select throws_ok($$select public.resolve_report('00000000-0000-0000-0000-0000000000ff', 'dismissed')$$,
  '22023', 'unknown_report', 'an unknown report is refused');

-- Songs. -----------------------------------------------------------------------------

select results_eq($$select id from public.moderator_songs() where id in ('fikir', 'selam', 'draft-song')$$,
  $$values ('fikir'), ('selam')$$, 'approved songs by title, not drafts');
select results_eq($$select id, artist, line_count from public.moderator_songs('  TEWOD ')$$,
  $$values ('selam', 'Tewodros', 2)$$, 'searched by artist, any case, with the line count');
select is((select count(*)::integer from public.moderator_songs(null, 1, 1)), 1, 'paged');

select is(public.set_song_hidden('selam', true), 'hidden'::public.song_status,
  'a moderator hides a song');
select is((select status::text from public.moderator_songs('selam') where id = 'selam'), 'hidden',
  'it is still listed for moderators');
select is((select count(*)::integer from public.song_index() where id = 'selam'), 0,
  'it leaves the song index');
select is(public.get_song('selam'), null, 'and get_song');
select is(public.moderator_song('selam') -> 'song' ->> 'title', 'Selam',
  'moderators still read it');
select is(public.moderator_song('draft-song'), null, 'but not drafts');
reset role;
create temp table edit (id uuid);
with i as (insert into public.contributions (author_id, kind, payload, song_id, base_version)
  values ('00000000-0000-0000-0000-0000000000a1', 'edit_lyrics',
    pg_temp.song('selam', 'Selam 2'), 'selam', 1) returning id)
insert into edit select id from i;
grant select on edit to authenticated;
set local role authenticated;
select throws_ok($$select public.review_contribution((select id from edit), 'approved')$$,
  '22023', 'unknown_song', 'an edit of a hidden song cannot be approved');
select throws_ok($$select public.set_song_hidden('draft-song', true)$$, '22023', 'unknown_song',
  'a draft cannot be hidden');
select throws_ok($$select public.set_song_hidden('nope', false)$$, '22023', 'unknown_song',
  'nor an unknown song restored');

select is(public.set_song_hidden('selam', false), 'approved'::public.song_status,
  'a moderator restores it');
select is((select count(*)::integer from public.song_index() where id = 'selam'), 1,
  'it is back in the index');
reset role;
select is((select approved_at from public.songs where id = 'selam'), '2026-01-01'::timestamptz,
  'keeping when it was first approved');

select * from finish();
rollback;
