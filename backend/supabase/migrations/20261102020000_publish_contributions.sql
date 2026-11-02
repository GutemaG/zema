-- Publishing approved contributions (intent 006, bolt 041, story 003).
--
-- review_contribution (bolt 040) calls publish_contribution before it marks a
-- contribution approved, in the same transaction: any error here leaves the
-- contribution pending and the catalog unchanged. Recordings now keep where they
-- come from (a YouTube video ID, or a file name for local and Telegram files);
-- song documents carry it as youtubeId and fileName.

alter table public.recordings
  add column youtube_id text check (youtube_id ~ '^[A-Za-z0-9_-]{11}$'),
  add column file_name text check (char_length(file_name) between 1 and 255);

-- song_document and seed_song, as in bolt 021, with the source reference.
create or replace function public.song_document(target public.slug)
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
        'offsetMs', nullif(r.offset_ms, 0),
        'youtubeId', r.youtube_id,
        'fileName', r.file_name
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

create or replace function public.seed_song(doc jsonb, status public.song_status default 'approved')
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
    insert into public.recordings
      (id, song_id, source, artist, duration_ms, offset_ms, youtube_id, file_name)
    values (recording ->> 'id', target,
      public.recording_source_from_name(recording ->> 'source'),
      recording ->> 'artist', (recording ->> 'durationMs')::integer,
      coalesce((recording ->> 'offsetMs')::integer, 0),
      recording ->> 'youtubeId', recording ->> 'fileName');
  end loop;
  insert into public.sync_timings (recording_id, starts_ms)
  select t ->> 'recordingId', array(select jsonb_array_elements_text(t -> 'startsMs')::integer)
  from jsonb_array_elements(coalesce(doc -> 'timings', '[]')) as t;

  return case when existed then 'updated' else 'created' end;
end
$$;

-- Publishes [contribution] into the catalog and returns its song's id. The
-- rules run again first, against the catalog as it is now: for example a sync
-- for a song corrected since it was submitted fails with timing_count.
create or replace function public.publish_contribution(contribution public.contributions)
returns text
language plpgsql
set search_path = ''
as $$
declare
  payload jsonb := contribution.payload;
  song jsonb := payload -> 'song';
  recording jsonb := payload -> 'recordings' -> 0;
  timing jsonb := payload -> 'timings' -> 0;
  target text := contribution.song_id;
  base text;
  suffix integer := 2;
  sung integer;
begin
  perform public.check_contribution(
    contribution.kind, contribution.song_id, contribution.base_version, payload);
  if recording is not null
     and exists (select 1 from public.recordings r where r.id = recording ->> 'id') then
    raise exception 'bad_recording' using errcode = '22023';
  end if;

  if contribution.kind = 'new_song' then
    base := song ->> 'id';
    target := base;
    while exists (select 1 from public.songs s where s.id = target) loop
      target := left(base, 120 - char_length('-' || suffix)) || '-' || suffix;
      suffix := suffix + 1;
    end loop;
    song := jsonb_set(song, '{id}', to_jsonb(target));
    song := jsonb_set(song, '{title}', to_jsonb(btrim(song ->> 'title')));
    payload := jsonb_set(payload, '{song}', song);
    if recording is not null then
      payload := jsonb_set(payload, '{recordings,0,songId}', to_jsonb(target));
    end if;
    perform public.seed_song(payload, 'approved');
    return target;
  end if;

  if contribution.kind = 'edit_lyrics' then
    update public.songs s
    set title = btrim(song ->> 'title'),
        transliteration = song ->> 'transliteration',
        artist = song ->> 'artist',
        album = song ->> 'album'
    where s.id = target;
    -- Lines and the play order go with their sections.
    delete from public.sections s where s.song_id = target;
    insert into public.sections (song_id, id, kind, position)
    select target, s.value ->> 'id', (s.value ->> 'kind')::public.section_kind, s.ordinality - 1
    from jsonb_array_elements(song -> 'sections') with ordinality as s;
    insert into public.lines (song_id, section_id, position, text, transliteration)
    select target, s.value ->> 'id', l.ordinality - 1, l.value ->> 'text', l.value ->> 'transliteration'
    from jsonb_array_elements(song -> 'sections') with ordinality as s,
      jsonb_array_elements(s.value -> 'lines') with ordinality as l;
    insert into public.play_order (song_id, position, section_id)
    select target, p.ordinality - 1, p.value
    from jsonb_array_elements_text(song -> 'playOrder') with ordinality as p;
    -- Timings that no longer have one start per sung line can't be shown.
    sung := public.sung_line_count(song);
    delete from public.sync_timings t
    using public.recordings r
    where r.id = t.recording_id and r.song_id = target
      and cardinality(t.starts_ms) <> sung;
    return target;
  end if;

  if contribution.kind = 'recording' then
    insert into public.recordings
      (id, song_id, source, artist, duration_ms, youtube_id, file_name)
    values (recording ->> 'id', target,
      public.recording_source_from_name(recording ->> 'source'),
      recording ->> 'artist', (recording ->> 'durationMs')::integer,
      recording ->> 'youtubeId', recording ->> 'fileName');
  end if;

  -- recording (with its timing) and sync_timing
  if timing is not null then
    insert into public.sync_timings (recording_id, starts_ms)
    values (timing ->> 'recordingId',
      array(select jsonb_array_elements_text(timing -> 'startsMs')::integer))
    on conflict (recording_id) do update set starts_ms = excluded.starts_ms;
  end if;
  return target;
end
$$;

revoke all on function public.publish_contribution from public, anon, authenticated;
