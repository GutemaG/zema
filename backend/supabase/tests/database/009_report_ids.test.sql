-- submit_report with report IDs (bolt 028, story 009): a repeat is stored once.
begin;
create extension if not exists pgtap with schema extensions;

-- Reports made against the local backend (emulator checks) would skew the counts.
delete from public.reports;

delete from public.songs;

select plan(10);

insert into public.songs (id, title, status) values ('open-song', 'Open', 'approved');

set local role anon;

select lives_ok(
  $$select public.submit_report('open-song', 'wrong_words', 'install-aaaa', null, 'first',
      'aaaaaaaa-0000-4000-8000-000000000001')$$,
  'a report with an ID is stored'
);
reset role;
create temporary table first_id on commit drop as
  select id from public.reports;
grant select on first_id to anon;
set local role anon;

select is(
  public.submit_report('open-song', 'wrong_words', 'install-aaaa', null, 'first',
    'aaaaaaaa-0000-4000-8000-000000000001'),
  (select id from first_id),
  'sending it again answers with the first report''s id'
);
reset role;
select is((select count(*)::int from public.reports), 1, 'and stores nothing more');
select is(
  (select client_id::text from public.reports),
  'aaaaaaaa-0000-4000-8000-000000000001',
  'the ID is kept with the report'
);

-- Four more reports reach the limit of 5.
set local role anon;
select public.submit_report('open-song', 'other', 'install-aaaa', null, null,
  ('aaaaaaaa-0000-4000-8000-00000000000' || n)::uuid)
  from generate_series(2, 5) n;
select lives_ok(
  $$select public.submit_report('open-song', 'wrong_words', 'install-aaaa', null, 'first',
      'aaaaaaaa-0000-4000-8000-000000000001')$$,
  'a repeat at the daily limit is still accepted'
);
select throws_ok(
  $$select public.submit_report('open-song', 'other', 'install-aaaa', null, null,
      'aaaaaaaa-0000-4000-8000-000000000009')$$,
  'PT429', 'Too many reports today', 'a new report at the limit is refused'
);
reset role;
select is((select count(*)::int from public.reports), 5, 'repeats are not counted');

set local role anon;
select lives_ok(
  $$select public.submit_report('open-song', 'wrong_words', 'install-bbbb', null, null,
      'aaaaaaaa-0000-4000-8000-000000000001')$$,
  'the same ID from another install is its own report'
);
select lives_ok(
  $$select public.submit_report('open-song', 'other', 'install-bbbb')$$,
  'a report with no ID works as before'
);
reset role;
select is(
  (select count(*)::int from public.reports
    where install_hash = encode(extensions.digest('install-bbbb', 'sha256'), 'hex')),
  2,
  'both stored for the other install'
);

select * from finish();
rollback;
