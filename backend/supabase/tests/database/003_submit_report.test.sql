-- submit_report (bolt 019): checked, hashed and rate-limited reports.
begin;
create extension if not exists pgtap with schema extensions;

-- Start from an empty catalog (the seed songs come back on rollback).
delete from public.songs;

select plan(17);

insert into public.songs (id, title, status) values
  ('open-song', 'Open', 'approved'),
  ('other-song', 'Other', 'approved'),
  ('draft-song', 'Draft', 'draft');
insert into public.recordings (id, song_id, source) values
  ('open-rec', 'open-song', 'bundled'),
  ('other-rec', 'other-song', 'bundled');

set local role anon;

select lives_ok(
  $$select public.submit_report('open-song', 'wrong_words', 'install-aaaa', 'open-rec', '  Line 2 is wrong  ')$$,
  'anon can report an approved song'
);
select is_empty('select * from public.reports', 'but still cannot read reports');

reset role;
select results_eq(
  $$select song_id::text, recording_id::text, reason::text, note from public.reports$$,
  $$values ('open-song', 'open-rec', 'wrong_words', 'Line 2 is wrong')$$,
  'the report is stored with the note trimmed'
);
select is(
  (select install_hash from public.reports),
  encode(extensions.digest('install-aaaa', 'sha256'), 'hex'),
  'the install ID is stored as its SHA-256 hash'
);
select is(
  (select count(*)::int from public.reports where install_hash like '%install-aaaa%'),
  0,
  'never as the raw ID'
);

set local role anon;
select lives_ok(
  $$select public.submit_report('open-song', 'other', 'install-aaaa', null, '   ')$$,
  'a blank note is allowed'
);
reset role;
select is((select count(*)::int from public.reports where note is null), 1,
  'and stored as null');

-- Validation ------------------------------------------------------------------------
set local role anon;
select throws_ok($$select public.submit_report('no-such-song', 'other', 'install-aaaa')$$,
  '22023', 'Unknown song', 'an unknown song is refused');
select throws_ok($$select public.submit_report('draft-song', 'other', 'install-aaaa')$$,
  '22023', 'Unknown song', 'a draft song gets the same answer');
select throws_ok($$select public.submit_report('open-song', 'other', 'install-aaaa', 'other-rec')$$,
  '22023', 'Unknown recording', 'a recording of another song is refused');
select throws_ok($$select public.submit_report('open-song', 'other', 'install-aaaa', null, repeat('x', 501))$$,
  '22023', 'Note too long', 'a note over 500 characters is refused');
select throws_ok($$select public.submit_report('open-song', 'other', 'short')$$,
  '22023', 'Invalid install ID', 'a short install ID is refused');
select throws_ok($$select public.submit_report('open-song', 'other', null)$$,
  '22023', 'Invalid install ID', 'a missing install ID is refused');

-- Rate limit: 5 per install in any 24 hours ------------------------------------------
-- install-aaaa has 2 so far.
select public.submit_report('open-song', 'other', 'install-aaaa');
select public.submit_report('open-song', 'other', 'install-aaaa');
select public.submit_report('open-song', 'other', 'install-aaaa');
select throws_ok($$select public.submit_report('open-song', 'other', 'install-aaaa')$$,
  'PT429', 'Too many reports today', 'the 6th report in 24 hours is refused');
select lives_ok($$select public.submit_report('open-song', 'other', 'install-bbbb')$$,
  'another install is unaffected');

reset role;
update public.reports set created_at = now() - interval '25 hours'
  where install_hash = encode(extensions.digest('install-aaaa', 'sha256'), 'hex')
    and note is null;
set local role anon;
select lives_ok($$select public.submit_report('open-song', 'other', 'install-aaaa')$$,
  'reports older than 24 hours no longer count');

reset role;
select ok(
  not has_function_privilege('public', 'public.submit_report(public.slug, public.report_reason, text, public.slug, text)', 'execute'),
  'only anon and authenticated may call it, not PUBLIC'
);

select * from finish();
rollback;
