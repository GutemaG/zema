-- Songs as documents (intent 004, bolt 021, story 006).
--
-- A song's document is the JSON zema_core reads and writes:
--   { "song": Song.toJson(), "recordings": [Recording.toJson()],
--     "timings": [SyncTiming.toJson()] }
-- Optional keys are left out, as in Dart, so documents compare equal however
-- they were built. get_song serves them to the app; seed_song writes them.

-- Dart's RecordingSource names.
create function public.recording_source_name(source public.recording_source)
returns text language sql immutable parallel safe
as $$ select case source when 'local_file' then 'localFile' else source::text end $$;

create function public.recording_source_from_name(name text)
returns public.recording_source language sql immutable parallel safe
as $$ select (case name when 'localFile' then 'local_file' else name end)::public.recording_source $$;

-- The document of song [target], whatever its status; null if there is none.
create function public.song_document(target public.slug)
returns jsonb
language sql
stable
set search_path = ''
as $$
  select jsonb_strip_nulls(jsonb_build_object(
    'song', jsonb_build_object(
      'id', s.id,
      'title', s.title,
      'transliteration', s.transliteration,
      'artist', s.artist,
      'album', s.album,
      'sections', coalesce((
        select jsonb_agg(jsonb_build_object(
          'id', sec.id,
          'kind', sec.kind,
          'lines', coalesce((
            select jsonb_agg(jsonb_build_object(
              'text', l.text, 'transliteration', l.transliteration
            ) order by l.position)
            from public.lines l
            where l.song_id = s.id and l.section_id = sec.id
          ), '[]'::jsonb)
        ) order by sec.position)
        from public.sections sec where sec.song_id = s.id
      ), '[]'::jsonb),
      'playOrder', (
        select jsonb_agg(p.section_id order by p.position)
        from public.play_order p where p.song_id = s.id
      )
    ),
    'recordings', coalesce((
      select jsonb_agg(jsonb_build_object(
        'id', r.id,
        'songId', r.song_id,
        'source', public.recording_source_name(r.source),
        'artist', r.artist,
        'durationMs', r.duration_ms,
        'offsetMs', nullif(r.offset_ms, 0)
      ) order by r.created_at, r.id)
      from public.recordings r where r.song_id = s.id
    ), '[]'::jsonb),
    'timings', coalesce((
      select jsonb_agg(jsonb_build_object(
        'recordingId', t.recording_id,
        'startsMs', to_jsonb(t.starts_ms)
      ) order by r.created_at, r.id)
      from public.sync_timings t
      join public.recordings r on r.id = t.recording_id
      where r.song_id = s.id
    ), '[]'::jsonb)
  ))
  from public.songs s
  where s.id = target
$$;

revoke all on function public.song_document from public, anon, authenticated;

-- The document of an approved song, or null. What the app downloads.
create function public.get_song(song_id text)
returns jsonb
language sql
stable
security definer
set search_path = ''
as $$
  select public.song_document(s.id)
  from public.songs s
  where s.id = get_song.song_id and s.status = 'approved'
$$;

revoke all on function public.get_song from public;
grant execute on function public.get_song to anon, authenticated;

-- Stores [doc] (see above) as a song with [status]. Returns 'unchanged' when
-- the stored song already equals it, so seeding again changes nothing (not
-- even the version); otherwise replaces the song's parts and returns
-- 'updated' or 'created'. For the seed and, later, moderators; not callable
-- from the app.
create function public.seed_song(doc jsonb, status public.song_status default 'approved')
returns text
language plpgsql
set search_path = ''
as $$
declare
  song jsonb := doc -> 'song';
  target public.slug := song ->> 'id';
  existed boolean;
  recording jsonb;
  timing jsonb;
  sung integer := 0;
  order_ids text[];
begin
  if song is null or target is null or coalesce(trim(song ->> 'title'), '') = '' then
    raise exception 'A song document needs song.id and song.title' using errcode = '22023';
  end if;
  if jsonb_typeof(song -> 'sections') is distinct from 'array' then
    raise exception 'Song % has no sections list', target using errcode = '22023';
  end if;

  -- One start per sung line, for every timing.
  order_ids := coalesce(
    array(select jsonb_array_elements_text(song -> 'playOrder')),
    array(select s ->> 'id' from jsonb_array_elements(song -> 'sections') s)
  );
  if cardinality(order_ids) = 0 then
    order_ids := array(select s ->> 'id' from jsonb_array_elements(song -> 'sections') s);
  end if;
  select coalesce(sum(jsonb_array_length(s -> 'lines')), 0) into sung
  from unnest(order_ids) as o(id)
  join jsonb_array_elements(song -> 'sections') as s on s ->> 'id' = o.id;
  for timing in select * from jsonb_array_elements(coalesce(doc -> 'timings', '[]')) loop
    if jsonb_array_length(timing -> 'startsMs') <> sung then
      raise exception 'Timing % has % starts for % sung lines of %',
        timing ->> 'recordingId', jsonb_array_length(timing -> 'startsMs'), sung, target
        using errcode = '22023';
    end if;
  end loop;

  select exists (select 1 from public.songs s where s.id = target) into existed;
  if existed and public.song_document(target) = jsonb_strip_nulls(doc) then
    if (select s.status from public.songs s where s.id = target) = status then
      return 'unchanged';
    end if;
    update public.songs s set status = seed_song.status where s.id = target;
    return 'updated';
  end if;

  insert into public.songs (id, title, transliteration, artist, album, status)
  values (target, song ->> 'title', song ->> 'transliteration', song ->> 'artist',
    song ->> 'album', status)
  on conflict (id) do update set
    title = excluded.title,
    transliteration = excluded.transliteration,
    artist = excluded.artist,
    album = excluded.album,
    status = excluded.status;

  delete from public.sections s where s.song_id = target;
  delete from public.recordings r where r.song_id = target;

  insert into public.sections (song_id, id, kind, position)
  select target, s.value ->> 'id', (s.value ->> 'kind')::public.section_kind, s.ordinality - 1
  from jsonb_array_elements(song -> 'sections') with ordinality as s;
  insert into public.lines (song_id, section_id, position, text, transliteration)
  select target, s.value ->> 'id', l.ordinality - 1, l.value ->> 'text', l.value ->> 'transliteration'
  from jsonb_array_elements(song -> 'sections') with ordinality as s,
    jsonb_array_elements(s.value -> 'lines') with ordinality as l;
  insert into public.play_order (song_id, position, section_id)
  select target, p.ordinality - 1, p.value
  from jsonb_array_elements_text(coalesce(song -> 'playOrder', '[]')) with ordinality as p;

  for recording in select * from jsonb_array_elements(coalesce(doc -> 'recordings', '[]')) loop
    insert into public.recordings (id, song_id, source, artist, duration_ms, offset_ms)
    values (recording ->> 'id', target,
      public.recording_source_from_name(recording ->> 'source'),
      recording ->> 'artist', (recording ->> 'durationMs')::integer,
      coalesce((recording ->> 'offsetMs')::integer, 0));
  end loop;
  insert into public.sync_timings (recording_id, starts_ms)
  select t ->> 'recordingId', array(select jsonb_array_elements_text(t -> 'startsMs')::integer)
  from jsonb_array_elements(coalesce(doc -> 'timings', '[]')) as t;

  return case when existed then 'updated' else 'created' end;
end
$$;

revoke all on function public.seed_song from public, anon, authenticated;
grant execute on function public.seed_song to service_role;
