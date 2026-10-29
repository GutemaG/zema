-- Backups (bolt 030): one private backup per user, saved only through save_backup.
begin;
create extension if not exists pgtap with schema extensions;

select plan(27);

insert into auth.users (id, email) values
  ('00000000-0000-0000-0000-0000000000a1', 'a@example.com'),
  ('00000000-0000-0000-0000-0000000000b1', 'b@example.com');

-- A document whose text form is exactly n bytes: {"x": "<n - 9 letters>"}.
create function pg_temp.doc_of(n int) returns jsonb language sql
  as $$ select jsonb_build_object('x', repeat('a', n - 9)) $$;

-- Saving. -------------------------------------------------------------------------

set local role authenticated;
set local request.jwt.claims = '{"sub": "00000000-0000-0000-0000-0000000000a1", "role": "authenticated"}';

select lives_ok(
  $$select public.save_backup('{"favorites": [1, 2]}', 1, '  Pixel 7 ')$$,
  'a user saves a backup'
);
select results_eq(
  $$select format, document, device, size_bytes from public.backups$$,
  $$values (1, '{"favorites": [1, 2]}'::jsonb, 'Pixel 7', octet_length('{"favorites": [1, 2]}'))$$,
  'the row holds the format, document, trimmed device and size'
);
select ok(
  (select updated_at = now() from public.backups),
  'the time is set by the server'
);
-- now() is fixed inside a transaction, so back-date the first save to see the new time.
reset role;
update public.backups set updated_at = now() - interval '1 day';
set local role authenticated;

select lives_ok(
  $$select public.save_backup('{"favorites": [3]}', 2)$$,
  'saving again'
);
select ok(
  (select updated_at = now() from public.backups),
  'a replaced backup gets the new time'
);
select results_eq(
  $$select count(*)::int, max(format), max(document::text), bool_and(device is null)
    from public.backups$$,
  $$values (1, 2, '{"favorites": [3]}', true)$$,
  'replaces the backup: one row, the new document, format and device'
);
select is(
  public.save_backup('{}', 1),
  now(),
  'save_backup returns the saved time'
);

-- Size and input. -----------------------------------------------------------------

select lives_ok(
  $$select public.save_backup(pg_temp.doc_of(2097152), 1)$$,
  'exactly 2 MB is accepted'
);
select is((select size_bytes from public.backups), 2097152, 'and its size is recorded');
select throws_ok(
  $$select public.save_backup(pg_temp.doc_of(2097153), 1)$$,
  '54000', 'Backup too large',
  'one byte over 2 MB is refused'
);
select throws_ok(
  $$select public.save_backup('[1, 2]', 1)$$,
  '22023', null,
  'a document that is not an object is refused'
);
select throws_ok(
  $$select public.save_backup(null, 1)$$,
  '22023', null,
  'a missing document is refused'
);
select throws_ok(
  $$select public.save_backup('{}', 0)$$,
  '22023', null,
  'format 0 is refused'
);
select throws_ok(
  $$select public.save_backup('{}', 1, repeat('d', 101))$$,
  '22023', null,
  'a device name over 100 characters is refused'
);

-- Direct writes. ------------------------------------------------------------------

select throws_ok(
  $$insert into public.backups (user_id, format, document) values (auth.uid(), 1, '{}')$$,
  '42501', null,
  'a user cannot insert into backups'
);
select throws_ok(
  $$update public.backups set format = 9$$,
  '42501', null,
  'or update it'
);
select throws_ok(
  $$delete from public.backups$$,
  '42501', null,
  'or delete from it'
);

-- Other users. --------------------------------------------------------------------

select public.save_backup('{"owner": "a"}', 1);

set local request.jwt.claims = '{"sub": "00000000-0000-0000-0000-0000000000b1", "role": "authenticated"}';
select is_empty('select * from public.backups', 'another user sees no backup');
select lives_ok(
  $$select public.save_backup('{"owner": "b"}', 1)$$,
  'and saves their own'
);
select results_eq(
  $$select document ->> 'owner' from public.backups$$,
  $$values ('b')$$,
  'they read only their own'
);

set local request.jwt.claims = '{"role": "authenticated"}';
select throws_ok(
  $$select public.save_backup('{}', 1)$$,
  '28000', 'Not signed in',
  'with no user in the token, saving is refused'
);

set local role anon;
select throws_ok(
  $$select public.save_backup('{}', 1)$$,
  '42501', null,
  'anon cannot call save_backup'
);
select is_empty('select * from public.backups', 'anon reads no backups');

reset role;
select results_eq(
  $$select user_id::text, document ->> 'owner' from public.backups order by 2$$,
  $$values ('00000000-0000-0000-0000-0000000000a1', 'a'),
           ('00000000-0000-0000-0000-0000000000b1', 'b')$$,
  'each user has one backup, and B''s save did not touch A''s'
);
select ok(
  (select proconfig is not null from pg_proc where proname = 'save_backup'),
  'save_backup runs with a fixed search_path'
);

delete from auth.users where id = '00000000-0000-0000-0000-0000000000b1';
select is(
  (select count(*)::int from public.backups),
  1,
  'deleting a user removes their backup'
);
select is(
  (select count(*)::int from pg_policies where tablename = 'backups'),
  1,
  'backups have one policy (read your own)'
);

select * from finish();
rollback;
