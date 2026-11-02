-- Reviewing (bolt 040): only moderators read the queue and review; no
-- self-review; a note for request changes and reject; one decision per
-- contribution; the role is granted only on the server.
begin;
create extension if not exists pgtap with schema extensions;

select plan(42);

insert into auth.users (id, email, raw_user_meta_data) values
  ('00000000-0000-0000-0000-0000000000a1', 'a@example.com', '{"full_name": "Abebe"}'),
  ('00000000-0000-0000-0000-0000000000c1', 'c@example.com', '{}'),
  ('00000000-0000-0000-0000-0000000000d1', 'mod@example.com', '{}'),
  ('00000000-0000-0000-0000-0000000000e1', 'admin@example.com', '{}');
insert into public.user_roles (user_id, role) values
  ('00000000-0000-0000-0000-0000000000d1', 'moderator'),
  ('00000000-0000-0000-0000-0000000000e1', 'admin');

create function pg_temp.song(id text default 'selam') returns jsonb language sql as $$
  select jsonb_build_object(
    'id', id, 'title', 'Selam',
    'sections', jsonb_build_array(jsonb_build_object('id', 'v', 'kind', 'verse',
      'lines', jsonb_build_array(jsonb_build_object('text', 'a')))),
    'playOrder', jsonb_build_array('v'))
$$;

select public.seed_song(jsonb_build_object('song', pg_temp.song('test-song'),
  'recordings', jsonb_build_array(jsonb_build_object(
    'id', 'test-rec', 'songId', 'test-song', 'source', 'localFile', 'fileName', 'a.mp3'))));

-- Contributions, inserted as the owner: a1's three pending (oldest first), one
-- already approved, and one pending by the moderator.
create function pg_temp.add(
  author text, kind public.contribution_kind, payload jsonb, song text default null,
  status public.contribution_status default 'pending', age interval default '0'
) returns uuid language sql as $$
  insert into public.contributions (author_id, kind, payload, song_id, status, submitted_at)
  values (author::uuid, kind, payload, song, status, now() - age)
  returning id
$$;
create temp table c as select
  pg_temp.add('00000000-0000-0000-0000-0000000000a1', 'new_song',
    jsonb_build_object('song', pg_temp.song('first')), age => '3 hours') as first,
  pg_temp.add('00000000-0000-0000-0000-0000000000a1', 'sync_timing',
    jsonb_build_object('timings', jsonb_build_array(jsonb_build_object(
      'recordingId', 'test-rec', 'startsMs', jsonb_build_array(1000)))),
    'test-song', age => '2 hours') as second,
  pg_temp.add('00000000-0000-0000-0000-0000000000a1', 'new_song',
    jsonb_build_object('song', pg_temp.song('third')), age => '1 hour') as third,
  pg_temp.add('00000000-0000-0000-0000-0000000000a1', 'new_song',
    jsonb_build_object('song', pg_temp.song('done')), status => 'approved') as done,
  pg_temp.add('00000000-0000-0000-0000-0000000000d1', 'new_song',
    jsonb_build_object('song', pg_temp.song('mine'))) as mine;
grant select on c to authenticated;

create function pg_temp.act_as(user_id text) returns void language sql as $$
  select set_config('request.jwt.claims',
    json_build_object('sub', user_id, 'role', 'authenticated')::text, true)
$$;

-- Who may read the queue. -----------------------------------------------------------

set local role authenticated;
select pg_temp.act_as('00000000-0000-0000-0000-0000000000c1');
select throws_ok('select * from public.moderator_queue()', '42501', 'not_moderator',
  'a contributor cannot read the queue');
set local request.jwt.claims = '{"role": "authenticated"}';
select throws_ok('select * from public.moderator_queue()', '28000', 'not_signed_in',
  'no user: not signed in');
set local role anon;
select throws_ok('select * from public.moderator_queue()', '42501', null,
  'anon cannot call it');

-- The queue. ------------------------------------------------------------------------

set local role authenticated;
select pg_temp.act_as('00000000-0000-0000-0000-0000000000d1');
select results_eq(
  'select id from public.moderator_queue()',
  'select unnest(array[first, second, third]) from c',
  'pending contributions by others, oldest first; not approved ones, not their own');
select results_eq(
  $$select id from public.moderator_queue('sync_timing')$$,
  'select second from c',
  'filtered by kind');
select results_eq(
  $$select author_name, song_id, current_version is not null, current_document #>> '{song,id}', revision
    from public.moderator_queue() where id = (select second from c)$$,
  $$values ('Abebe', 'test-song', true, 'test-song', 1)$$,
  'with the author''s name and the song as it is now');
select results_eq(
  $$select song_id, current_version, current_document
    from public.moderator_queue() where id = (select first from c)$$,
  $$values (null::text, null::integer, null::jsonb)$$,
  'a new song has no current song');
select pg_temp.act_as('00000000-0000-0000-0000-0000000000e1');
select is((select count(*)::int from public.moderator_queue()), 4,
  'an admin reads it too, with the moderator''s contribution');

-- Refused reviews. ------------------------------------------------------------------

select pg_temp.act_as('00000000-0000-0000-0000-0000000000d1');
select throws_ok($$select public.review_contribution((select third from c), 'changes_requested')$$,
  '22023', 'note_required', 'request changes needs a note');
select throws_ok($$select public.review_contribution((select third from c), 'changes_requested', '   ')$$,
  '22023', 'note_required', 'a blank note is no note');
select throws_ok($$select public.review_contribution((select third from c), 'rejected')$$,
  '22023', 'note_required', 'reject needs a reason');
select throws_ok($$select public.review_contribution((select third from c), 'rejected', repeat('n', 1001))$$,
  '22023', 'note_too_long', 'a note over 1,000 characters');
select lives_ok($$select public.review_contribution((select third from c), 'rejected', repeat('n', 1000))$$,
  'a 1,000-character note is fine');
select throws_ok($$select public.review_contribution((select first from c), 'pending')$$,
  '22023', 'bad_decision', 'pending is not a decision');
select throws_ok($$select public.review_contribution(gen_random_uuid(), 'approved')$$,
  '22023', 'unknown_contribution', 'an unknown contribution');
select throws_ok($$select public.review_contribution((select mine from c), 'approved')$$,
  '42501', 'own_contribution', 'a moderator cannot review their own');
select pg_temp.act_as('00000000-0000-0000-0000-0000000000c1');
select throws_ok($$select public.review_contribution((select first from c), 'approved')$$,
  '42501', 'not_moderator', 'a contributor cannot review');
set local role anon;
select throws_ok($$select public.review_contribution((select first from c), 'approved')$$,
  '42501', null, 'anon cannot call it');

-- Reviews. --------------------------------------------------------------------------

set local role authenticated;
select pg_temp.act_as('00000000-0000-0000-0000-0000000000d1');
select is(
  public.review_contribution((select second from c), 'changes_requested', '  Check line 1 '),
  'test-song', 'request changes returns the song');
reset role;
select results_eq(
  $$select status::text, review_note, reviewer_id, reviewed_at = now()
    from public.contributions where id = (select second from c)$$,
  $$values ('changes_requested', 'Check line 1', '00000000-0000-0000-0000-0000000000d1'::uuid, true)$$,
  'the status, trimmed note, reviewer and time are set');
set local role authenticated;
select pg_temp.act_as('00000000-0000-0000-0000-0000000000e1');
select throws_ok($$select public.review_contribution((select second from c), 'approved')$$,
  'PT409', 'already_reviewed', 'a second review is refused');
select throws_ok($$select public.review_contribution((select third from c), 'approved')$$,
  'PT409', 'already_reviewed', 'also after a rejection');
select throws_ok($$select public.review_contribution((select done from c), 'rejected', 'no')$$,
  'PT409', 'already_reviewed', 'and for one approved before');
reset role;
select results_eq(
  $$select status::text, reviewer_id from public.contributions where id = (select second from c)$$,
  $$values ('changes_requested', '00000000-0000-0000-0000-0000000000d1'::uuid)$$,
  'and changes nothing');
set local role authenticated;
select is(
  public.review_contribution((select first from c), 'approved'),
  'first', 'an approval returns the published song');
reset role;
select results_eq(
  $$select status::text, review_note, song_id::text from public.contributions where id = (select first from c)$$,
  $$values ('approved', null::text, 'first')$$,
  'approved with no note, pointing at its song');

-- The author sees the outcome.
set local role authenticated;
select pg_temp.act_as('00000000-0000-0000-0000-0000000000a1');
select results_eq(
  $$select status::text, review_note from public.contributions where id = (select second from c)$$,
  $$values ('changes_requested', 'Check line 1')$$,
  'the author reads the decision and the note');

-- A moderator whose role was removed.
reset role;
delete from public.user_roles where user_id = '00000000-0000-0000-0000-0000000000d1';
insert into public.contributions (author_id, kind, payload)
values ('00000000-0000-0000-0000-0000000000a1', 'new_song', jsonb_build_object('song', pg_temp.song('late')));
set local role authenticated;
select pg_temp.act_as('00000000-0000-0000-0000-0000000000d1');
select throws_ok('select * from public.moderator_queue()', '42501', 'not_moderator',
  'a former moderator cannot read the queue');
select throws_ok(
  $$select public.review_contribution((select id from public.contributions where payload #>> '{song,id}' = 'late'), 'approved')$$,
  '42501', 'not_moderator', 'or review');

-- Granting the role. ----------------------------------------------------------------

select throws_ok($$select public.set_moderator('c@example.com', true)$$,
  '42501', null, 'the app cannot grant the role');
reset role;
select is(public.set_moderator('c@example.com', true), 'granted', 'the owner grants it');
select ok(public.is_moderator('00000000-0000-0000-0000-0000000000c1'), 'and the user is a moderator');
select is(public.set_moderator('  C@Example.com ', true), 'unchanged', 'the email is matched without case or spaces');
select is(public.set_moderator('c@example.com', false), 'revoked', 'the owner removes it');
select ok(not public.is_moderator('00000000-0000-0000-0000-0000000000c1'), 'and the user is not a moderator');
select results_eq(
  $$select role::text from public.user_roles where user_id = '00000000-0000-0000-0000-0000000000c1'$$,
  $$values ('contributor')$$,
  'other roles stay');
select is(public.set_moderator('c@example.com', false), 'unchanged', 'removing again changes nothing');
select throws_ok($$select public.set_moderator('nobody@example.com', true)$$,
  '22023', 'unknown_email', 'an unknown email');
select ok(public.is_moderator('00000000-0000-0000-0000-0000000000e1'), 'admins count as moderators');
select ok(
  has_function_privilege('service_role', 'public.set_moderator(text, boolean)', 'execute'),
  'service_role may run set_moderator');
select ok(
  not has_function_privilege('authenticated', 'public.set_moderator(text, boolean)', 'execute')
    and not has_function_privilege('anon', 'public.set_moderator(text, boolean)', 'execute'),
  'the app''s roles may not run it at all');
select ok(
  not has_function_privilege('authenticated', 'public.publish_contribution(public.contributions)', 'execute'),
  'the app cannot publish directly');

select * from finish();
rollback;
