-- Profiles and roles (bolt 029): made on sign-up, own rows only, name-only writes.
begin;
create extension if not exists pgtap with schema extensions;

select plan(32);

-- Test users, as Google sign-in would make them.
insert into auth.users (id, email, raw_user_meta_data) values
  ('00000000-0000-0000-0000-00000000000a', 'abebe@example.com',
   '{"full_name": "  Abebe Bikila ", "avatar_url": "https://example.com/a.png"}'),
  ('00000000-0000-0000-0000-00000000000b', 'tigist.h@example.com',
   '{"picture": "https://example.com/b.png"}'),
  ('00000000-0000-0000-0000-00000000000c', 'c@example.com',
   '{"name": "A name that is much longer than forty characters, really"}'),
  ('00000000-0000-0000-0000-00000000000d', 'dawit@example.com',
   '{"full_name": "   ", "name": ""}'),
  ('00000000-0000-0000-0000-00000000000e', null, '{}');

-- The trigger. --------------------------------------------------------------

select results_eq(
  $$select display_name, avatar_url from public.profiles
    where id = '00000000-0000-0000-0000-00000000000a'$$,
  $$values ('Abebe Bikila', 'https://example.com/a.png')$$,
  'Google full name (trimmed) and avatar are used'
);
select results_eq(
  $$select display_name, avatar_url from public.profiles
    where id = '00000000-0000-0000-0000-00000000000b'$$,
  $$values ('tigist.h', 'https://example.com/b.png')$$,
  'with no name, the email local part; picture when there is no avatar_url'
);
select is(
  (select display_name from public.profiles where id = '00000000-0000-0000-0000-00000000000c'),
  'A name that is much longer than forty ch',
  'a long name is cut to 40 characters'
);
select is(
  (select display_name from public.profiles where id = '00000000-0000-0000-0000-00000000000d'),
  'dawit',
  'a blank name falls back to the email'
);
select results_eq(
  $$select display_name, avatar_url from public.profiles
    where id = '00000000-0000-0000-0000-00000000000e'$$,
  $$values ('Zema user'::text, null::text)$$,
  'no name and no email gives "Zema user" and no avatar'
);
select results_eq(
  $$select count(*)::int from public.user_roles
    where role = 'contributor' and user_id::text like '00000000-0000-0000-0000-00000000000_'$$,
  $$values (5)$$,
  'every new user is a contributor'
);
select is(
  (select count(*)::int from public.user_roles
    where user_id::text like '00000000-0000-0000-0000-00000000000_'),
  5,
  'and has no other role'
);
select isnt(
  (select proconfig from pg_proc where proname = 'handle_new_user'),
  null,
  'the trigger function runs with a fixed search_path'
);
select ok(
  not has_function_privilege('authenticated', 'public.handle_new_user()', 'execute')
    and not has_function_privilege('anon', 'public.handle_new_user()', 'execute'),
  'the API roles cannot call the trigger function'
);

-- Reading. --------------------------------------------------------------------

set local role anon;
select is_empty('select * from public.profiles', 'anon reads no profiles');
select is_empty('select * from public.user_roles', 'anon reads no roles');

set local role authenticated;
set local request.jwt.claims = '{"sub": "00000000-0000-0000-0000-00000000000a", "role": "authenticated"}';

select results_eq(
  'select id::text from public.profiles',
  $$values ('00000000-0000-0000-0000-00000000000a')$$,
  'a user reads only their own profile'
);
select results_eq(
  'select user_id::text, role::text from public.user_roles',
  $$values ('00000000-0000-0000-0000-00000000000a', 'contributor')$$,
  'a user reads only their own roles'
);

-- Updating the name. ---------------------------------------------------------

select lives_ok(
  $$update public.profiles set display_name = '  Abebe B. ' where id = auth.uid()$$,
  'a user renames themselves'
);
select is(
  (select display_name from public.profiles where id = auth.uid()),
  'Abebe B.',
  'the new name is trimmed'
);
select lives_ok(
  $$update public.profiles set display_name = repeat('x', 40) where id = auth.uid()$$,
  'a 40-character name is accepted'
);
select throws_ok(
  $$update public.profiles set display_name = repeat('x', 41) where id = auth.uid()$$,
  '23514', null,
  'a 41-character name is refused'
);
select throws_ok(
  $$update public.profiles set display_name = '' where id = auth.uid()$$,
  '23514', null,
  'an empty name is refused'
);
select throws_ok(
  $$update public.profiles set display_name = '    ' where id = auth.uid()$$,
  '23514', null,
  'a name of only spaces is refused'
);
select throws_ok(
  $$update public.profiles set avatar_url = 'https://evil.example/x.png' where id = auth.uid()$$,
  '42501', null,
  'the avatar cannot be changed'
);
select throws_ok(
  $$update public.profiles set id = '00000000-0000-0000-0000-00000000000b' where id = auth.uid()$$,
  '42501', null,
  'the id cannot be changed'
);

-- With no WHERE clause no column is read, so only the update policy limits the rows
-- (a WHERE on id would also apply the read policy and hide a too-wide update policy).
update public.profiles set display_name = 'Hacked';
select is(
  (select display_name from public.profiles where id = auth.uid()),
  'Hacked',
  'an update of every row changes only the user''s own'
);
update public.profiles set display_name = repeat('x', 40) where id = auth.uid();

-- Inserting and deleting. ----------------------------------------------------

select throws_ok(
  $$insert into public.profiles (id, display_name) values (auth.uid(), 'Twin')$$,
  '42501', null,
  'a user cannot insert a profile'
);
select throws_ok(
  $$delete from public.profiles where id = auth.uid()$$,
  '42501', null,
  'a user cannot delete their profile'
);

-- Roles. -------------------------------------------------------------------------

select throws_ok(
  $$insert into public.user_roles (user_id, role) values (auth.uid(), 'moderator')$$,
  '42501', null,
  'a user cannot make themselves a moderator'
);
select throws_ok(
  $$update public.user_roles set role = 'admin' where user_id = auth.uid()$$,
  '42501', null,
  'a user cannot change their role'
);
select throws_ok(
  $$delete from public.user_roles where user_id = auth.uid()$$,
  '42501', null,
  'a user cannot delete their role'
);

-- Back to the owner to see what really happened.
reset role;

select is(
  (select display_name from public.profiles where id = '00000000-0000-0000-0000-00000000000b'),
  'tigist.h',
  'another user''s name is unchanged'
);
select is(
  (select count(*)::int from public.profiles where id = '00000000-0000-0000-0000-00000000000a'),
  1,
  'the profile is still there'
);
select is(
  (select display_name from public.profiles where id = '00000000-0000-0000-0000-00000000000a'),
  repeat('x', 40),
  'refused updates left the last good name'
);

-- Deleting the auth user. ----------------------------------------------------

delete from auth.users where id = '00000000-0000-0000-0000-00000000000a';

select is_empty(
  $$select 1 from public.profiles where id = '00000000-0000-0000-0000-00000000000a'$$,
  'deleting the auth user removes the profile'
);
select is_empty(
  $$select 1 from public.user_roles where user_id = '00000000-0000-0000-0000-00000000000a'$$,
  'and the roles'
);

select * from finish();
rollback;
