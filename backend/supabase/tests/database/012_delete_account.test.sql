-- delete_account (bolt 030): removes the caller and everything linked to them.
begin;
create extension if not exists pgtap with schema extensions;

delete from public.reports;

select plan(15);

insert into auth.users (id, email, raw_user_meta_data) values
  ('00000000-0000-0000-0000-0000000000a2', 'a@example.com', '{"full_name": "A"}'),
  ('00000000-0000-0000-0000-0000000000b2', 'b@example.com', '{"full_name": "B"}');
insert into auth.sessions (id, user_id) values
  ('00000000-0000-0000-0000-00000000aa01', '00000000-0000-0000-0000-0000000000a2'),
  ('00000000-0000-0000-0000-00000000bb01', '00000000-0000-0000-0000-0000000000b2');
insert into public.backups (user_id, format, document) values
  ('00000000-0000-0000-0000-0000000000a2', 1, '{}'),
  ('00000000-0000-0000-0000-0000000000b2', 1, '{}');
insert into public.contributions (author_id, kind, payload) values
  ('00000000-0000-0000-0000-0000000000a2', 'new_song', '{"title": "Kept"}');
select public.submit_report(
  (select id from public.songs where status = 'approved' limit 1), 'wrong_words', 'install-a2');

set local role authenticated;
set local request.jwt.claims = '{"sub": "00000000-0000-0000-0000-0000000000a2", "role": "authenticated"}';

select lives_ok('select public.delete_account()', 'a user deletes their account');
select lives_ok('select public.delete_account()', 'a second call does nothing and does not fail');

reset role;

select is_empty($$select 1 from auth.users where id = '00000000-0000-0000-0000-0000000000a2'$$,
  'the auth user is gone');
select is_empty($$select 1 from public.profiles where id = '00000000-0000-0000-0000-0000000000a2'$$,
  'the profile is gone');
select is_empty($$select 1 from public.user_roles where user_id = '00000000-0000-0000-0000-0000000000a2'$$,
  'the roles are gone');
select is_empty($$select 1 from public.backups where user_id = '00000000-0000-0000-0000-0000000000a2'$$,
  'the backup is gone');
select is_empty($$select 1 from auth.sessions where user_id = '00000000-0000-0000-0000-0000000000a2'$$,
  'the sessions are gone, so the user is signed out everywhere');

select results_eq(
  $$select author_id is null, payload ->> 'title' from public.contributions$$,
  $$values (true, 'Kept')$$,
  'a contribution is kept with no author'
);
select is((select count(*)::int from public.reports), 1, 'anonymous reports stay');

select is(
  (select count(*)::int from auth.users where id = '00000000-0000-0000-0000-0000000000b2')
  + (select count(*)::int from public.profiles where id = '00000000-0000-0000-0000-0000000000b2')
  + (select count(*)::int from public.user_roles where user_id = '00000000-0000-0000-0000-0000000000b2')
  + (select count(*)::int from public.backups where user_id = '00000000-0000-0000-0000-0000000000b2')
  + (select count(*)::int from auth.sessions where user_id = '00000000-0000-0000-0000-0000000000b2'),
  5,
  'another user keeps their user, profile, role, backup and session'
);

set local role authenticated;
set local request.jwt.claims = '{"role": "authenticated"}';
select throws_ok('select public.delete_account()', '28000', 'Not signed in',
  'with no user in the token, it is refused');

set local role anon;
select throws_ok('select public.delete_account()', '42501', null, 'anon cannot call it');

reset role;
select ok(
  not has_function_privilege('anon', 'public.delete_account()', 'execute'),
  'anon has no execute right'
);
select ok(
  has_function_privilege('authenticated', 'public.delete_account()', 'execute'),
  'signed-in users do'
);
select ok(
  (select proconfig is not null from pg_proc where proname = 'delete_account'),
  'it runs with a fixed search_path'
);

select * from finish();
rollback;
