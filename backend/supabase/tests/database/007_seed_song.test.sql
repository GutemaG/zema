-- seed_song and get_song (bolt 021): idempotent, checked, service-only.
begin;
create extension if not exists pgtap with schema extensions;

select plan(16);

create temporary table doc as select '{
  "song": {"id": "test-song", "title": "ሰላም", "transliteration": "Selam",
    "sections": [
      {"id": "v1", "kind": "verse", "lines": [{"text": "ሰላም ለኪ", "transliteration": "Selam leki"}]},
      {"id": "c", "kind": "chorus", "lines": [{"text": "ሃሌ ሉያ"}, {"text": "ሃሌ"}]}
    ],
    "playOrder": ["v1", "c", "c"]},
  "recordings": [{"id": "test-song", "songId": "test-song", "source": "localFile", "durationMs": 30000, "offsetMs": -250}],
  "timings": [{"recordingId": "test-song", "startsMs": [0, 1000, 2000, 3000, 4000]}]
}'::jsonb as d;

select is(public.seed_song((select d from doc)), 'created', 'a new song is created');
select is(public.get_song('test-song'), (select d from doc), 'get_song returns the same document');
select is(
  (select source::text from public.recordings where id = 'test-song'), 'local_file',
  'Dart source names map to the database''s'
);

create temporary table v as select version from public.songs where id = 'test-song';
select is(public.seed_song((select d from doc)), 'unchanged', 'seeding it again changes nothing');
select is((select version from public.songs where id = 'test-song'), (select version from v),
  'not even the version');

update doc set d = jsonb_set(d, '{song,sections,0,lines,0,text}', '"ሰላም ለኪ ማርያም"');
select is(public.seed_song((select d from doc)), 'updated', 'a changed line updates the song');
select ok((select version from public.songs where id = 'test-song') > (select version from v),
  'and bumps its version');
select is(public.get_song('test-song'), (select d from doc), 'and is served as given');
select is((select count(*)::int from public.search_songs('ሰላም ለኪ ማርያም')), 1,
  'and is searchable by its new line');

select is(public.seed_song((select d from doc), 'draft'), 'updated', 'a status change alone updates');
select is(public.get_song('test-song'), null, 'and a draft is not served');
select is(public.get_song('no-such-song'), null, 'an unknown song is null');

select throws_ok(
  $$select public.seed_song(jsonb_set((select d from doc), '{timings,0,startsMs}', '[0, 1000]'))$$,
  '22023', null, 'a timing that does not fit the sung lines is refused'
);
select throws_ok(
  $$select public.seed_song('{"song": {"id": "x", "sections": []}}')$$,
  '22023', null, 'a document without a title is refused'
);

set local role anon;
select throws_ok($$select public.seed_song('{}')$$, '42501', null, 'anon cannot seed');
reset role;
set local role authenticated;
select throws_ok($$select public.song_document('test-song')$$, '42501', null,
  'and cannot read documents of any status');

select * from finish();
rollback;
