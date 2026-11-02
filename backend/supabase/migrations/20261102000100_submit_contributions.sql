-- Submitting contributions (intent 006, bolt 039, story 001).
--
-- Signed-in users submit lyrics, corrections, recordings and timings through
-- submit_contribution, and fix one a moderator sent back through
-- resubmit_contribution. Both check the payload with contribution_error; users
-- read only their own contributions and nobody writes the table directly.
--
-- The payload is 004's song document ({song, recordings, timings}); each kind
-- uses part of it:
--   new_song     song (its id a slug the app proposes); at most one recording,
--                and at most one timing for it; no song_id
--   edit_lyrics  song only, with id = song_id; base_version required
--   recording    exactly one recording of song_id; at most one timing for it
--   sync_timing  exactly one timing, for an existing recording of song_id
-- Recordings carry youtubeId (youtube) or fileName (localFile, telegram).
--
-- Errors are raised with the code as the message; zema_core mirrors the list:
--   22023  bad_payload, title_required, title_too_long, field_too_long,
--          no_sections, empty_section, bad_section, too_many_lines,
--          play_order_empty, play_order_unknown_section, bad_recording,
--          bad_video_id, timing_count, timing_order, timing_past_duration,
--          youtube_not_synced, missing_song, missing_recording, missing_timing,
--          song_not_allowed, unknown_song, unknown_recording, bad_base_version,
--          not_editable
--   54000  payload_too_large
--   PT429  too_many_open (20 pending or changes_requested),
--          too_many_today (30 in 24 hours)
--   28000  not_signed_in

alter table public.contributions
  add column base_version integer check (base_version >= 1),
  add column submitted_at timestamptz not null default now(),
  add column revision integer not null default 1 check (revision >= 1),
  add column size_bytes integer generated always as (octet_length(payload::text)) stored
    check (size_bytes <= 262144);

create index contributions_author_status_idx on public.contributions (author_id, status);
create index contributions_author_created_at_idx on public.contributions (author_id, created_at);

create policy "Users read their own contributions" on public.contributions
  for select to authenticated
  using (author_id = auth.uid());

-- Validation -------------------------------------------------------------------

-- Whether [value] is a JSON whole number that fits an integer.
create function public.is_json_int(value jsonb)
returns boolean
language sql
immutable
set search_path = ''
as $$
  select case when jsonb_typeof(value) = 'number' then
    (value::text)::numeric = trunc((value::text)::numeric)
      and (value::text)::numeric between -2147483648 and 2147483647
  else false end
$$;

-- Whether [value] is absent, null or a JSON string of at most [max] characters.
create function public.is_optional_text(value jsonb, max integer)
returns boolean
language sql
immutable
set search_path = ''
as $$
  select value is null or jsonb_typeof(value) = 'null'
    or (jsonb_typeof(value) = 'string' and char_length(value #>> '{}') <= max)
$$;

-- How many lines a song document's song sings: its lines counted once per
-- play-order entry, or every section once when it has no play order.
create function public.sung_line_count(song jsonb)
returns integer
language sql
immutable
set search_path = ''
as $$
  with play as (
    select o.value as id
    from jsonb_array_elements_text(
      case when jsonb_typeof(song -> 'playOrder') = 'array'
        and jsonb_array_length(song -> 'playOrder') > 0
      then song -> 'playOrder'
      else coalesce((
        select jsonb_agg(s -> 'id') from jsonb_array_elements(song -> 'sections') s
      ), '[]') end
    ) as o
  )
  select coalesce(sum(jsonb_array_length(s -> 'lines')), 0)::integer
  from play
  join jsonb_array_elements(song -> 'sections') as s on s ->> 'id' = play.id
$$;

-- The first rule [song] breaks, or null.
create function public.song_payload_error(song jsonb)
returns text
language plpgsql
immutable
set search_path = ''
as $$
declare
  section jsonb;
  line jsonb;
  entry jsonb;
  ids text[] := '{}';
  written integer := 0;
begin
  if jsonb_typeof(song) is distinct from 'object' then
    return 'bad_payload';
  end if;
  if jsonb_typeof(song -> 'id') is distinct from 'string'
     or (song ->> 'id') !~ '^[a-z0-9]+(-[a-z0-9]+)*$'
     or char_length(song ->> 'id') > 120 then
    return 'bad_payload';
  end if;
  if song -> 'title' is not null and jsonb_typeof(song -> 'title') <> 'string' then
    return 'bad_payload';
  end if;
  if coalesce(btrim(song ->> 'title'), '') = '' then
    return 'title_required';
  end if;
  if char_length(btrim(song ->> 'title')) > 200 then
    return 'title_too_long';
  end if;
  if not (public.is_optional_text(song -> 'transliteration', 200)
      and public.is_optional_text(song -> 'artist', 200)
      and public.is_optional_text(song -> 'album', 200)) then
    return case
      when jsonb_typeof(coalesce(song -> 'transliteration', 'null')) not in ('string', 'null')
        or jsonb_typeof(coalesce(song -> 'artist', 'null')) not in ('string', 'null')
        or jsonb_typeof(coalesce(song -> 'album', 'null')) not in ('string', 'null')
      then 'bad_payload' else 'field_too_long' end;
  end if;

  if song -> 'sections' is null or jsonb_typeof(song -> 'sections') = 'null' then
    return 'no_sections';
  end if;
  if jsonb_typeof(song -> 'sections') <> 'array' then
    return 'bad_payload';
  end if;
  if jsonb_array_length(song -> 'sections') = 0 then
    return 'no_sections';
  end if;
  for section in select * from jsonb_array_elements(song -> 'sections') loop
    if jsonb_typeof(section) <> 'object'
       or jsonb_typeof(section -> 'id') is distinct from 'string'
       or coalesce(section ->> 'id', '') = ''
       or char_length(section ->> 'id') > 120
       or (section ->> 'id') = any (ids)
       or coalesce(section ->> 'kind', '') not in ('verse', 'chorus', 'bridge', 'other') then
      return 'bad_section';
    end if;
    ids := ids || (section ->> 'id');
    if jsonb_typeof(section -> 'lines') is distinct from 'array' then
      return case when section -> 'lines' is null then 'empty_section' else 'bad_payload' end;
    end if;
    if jsonb_array_length(section -> 'lines') = 0 then
      return 'empty_section';
    end if;
    for line in select * from jsonb_array_elements(section -> 'lines') loop
      if jsonb_typeof(line) <> 'object'
         or jsonb_typeof(line -> 'text') is distinct from 'string'
         or not public.is_optional_text(line -> 'transliteration', 500) then
        return 'bad_payload';
      end if;
      if btrim(line ->> 'text') = '' then
        return 'empty_section';
      end if;
      if char_length(line ->> 'text') > 500 then
        return 'field_too_long';
      end if;
      written := written + 1;
    end loop;
  end loop;
  if written > 300 then
    return 'too_many_lines';
  end if;

  if song -> 'playOrder' is null or jsonb_typeof(song -> 'playOrder') = 'null' then
    return 'play_order_empty';
  end if;
  if jsonb_typeof(song -> 'playOrder') <> 'array' then
    return 'bad_payload';
  end if;
  if jsonb_array_length(song -> 'playOrder') = 0 then
    return 'play_order_empty';
  end if;
  for entry in select * from jsonb_array_elements(song -> 'playOrder') loop
    if jsonb_typeof(entry) <> 'string' then
      return 'bad_payload';
    end if;
    if not ((entry #>> '{}') = any (ids)) then
      return 'play_order_unknown_section';
    end if;
  end loop;
  return null;
end
$$;

-- The first rule [recording] breaks as a recording of [song_id], or null.
create function public.recording_payload_error(recording jsonb, song_id text)
returns text
language plpgsql
immutable
set search_path = ''
as $$
declare
  source text := recording ->> 'source';
begin
  if jsonb_typeof(recording) is distinct from 'object' then
    return 'bad_payload';
  end if;
  if jsonb_typeof(recording -> 'id') is distinct from 'string'
     or (recording ->> 'id') !~ '^[a-z0-9]+(-[a-z0-9]+)*$'
     or char_length(recording ->> 'id') > 120
     or (recording ->> 'songId') is distinct from song_id
     or coalesce(source, '') not in ('localFile', 'telegram', 'youtube')
     or not public.is_optional_text(recording -> 'artist', 200) then
    return 'bad_recording';
  end if;
  if recording -> 'durationMs' is not null
     and not (public.is_json_int(recording -> 'durationMs')
       and (recording ->> 'durationMs')::integer > 0) then
    return 'bad_recording';
  end if;
  if source = 'youtube' then
    if jsonb_typeof(recording -> 'youtubeId') is distinct from 'string'
       or (recording ->> 'youtubeId') !~ '^[A-Za-z0-9_-]{11}$' then
      return 'bad_video_id';
    end if;
  elsif jsonb_typeof(recording -> 'fileName') is distinct from 'string'
     or btrim(recording ->> 'fileName') = ''
     or char_length(recording ->> 'fileName') > 255 then
    return 'bad_recording';
  end if;
  return null;
end
$$;

-- The first rule [timing] breaks as the timing of [recording_id] (from
-- [source], [duration_ms] long when known) for [sung] lines, or null.
create function public.timing_payload_error(
  timing jsonb,
  recording_id text,
  source text,
  duration_ms integer,
  sung integer
)
returns text
language plpgsql
immutable
set search_path = ''
as $$
declare
  start jsonb;
  previous integer;
  ms integer;
begin
  if jsonb_typeof(timing) is distinct from 'object'
     or jsonb_typeof(timing -> 'startsMs') is distinct from 'array' then
    return 'bad_payload';
  end if;
  if (timing ->> 'recordingId') is distinct from recording_id then
    return 'unknown_recording';
  end if;
  if source = 'youtube' then
    return 'youtube_not_synced';
  end if;
  for start in select * from jsonb_array_elements(timing -> 'startsMs') loop
    if not public.is_json_int(start) then
      return 'bad_payload';
    end if;
  end loop;
  if jsonb_array_length(timing -> 'startsMs') <> sung then
    return 'timing_count';
  end if;
  for start in select * from jsonb_array_elements(timing -> 'startsMs') loop
    ms := (start #>> '{}')::integer;
    if ms < 0 or ms <= previous then
      return 'timing_order';
    end if;
    if ms >= duration_ms then
      return 'timing_past_duration';
    end if;
    previous := ms;
  end loop;
  return null;
end
$$;

-- The first rule a contribution breaks, or null. Not callable from the API.
create function public.contribution_error(
  kind public.contribution_kind,
  song_id text,
  base_version integer,
  payload jsonb
)
returns text
language plpgsql
stable
set search_path = ''
as $$
declare
  song jsonb := payload -> 'song';
  recordings jsonb := payload -> 'recordings';
  timings jsonb := payload -> 'timings';
  recording jsonb;
  error text;
  current_version integer;
  stored public.recordings;
begin
  if jsonb_typeof(payload) is distinct from 'object'
     or jsonb_typeof(coalesce(song, '{}')) <> 'object'
     or jsonb_typeof(coalesce(recordings, '[]')) <> 'array'
     or jsonb_typeof(coalesce(timings, '[]')) <> 'array'
     or jsonb_array_length(coalesce(recordings, '[]')) > 1
     or jsonb_array_length(coalesce(timings, '[]')) > 1 then
    return 'bad_payload';
  end if;
  recording := recordings -> 0;

  if kind = 'new_song' then
    if song_id is not null then
      return 'song_not_allowed';
    end if;
    if base_version is not null then
      return 'bad_base_version';
    end if;
    if song is null then
      return 'missing_song';
    end if;
    error := public.song_payload_error(song);
    if error is not null then
      return error;
    end if;
    if recording is null then
      return case when timings -> 0 is null then null else 'missing_recording' end;
    end if;
    error := public.recording_payload_error(recording, song ->> 'id');
    if error is not null or timings -> 0 is null then
      return error;
    end if;
    return public.timing_payload_error(
      timings -> 0, recording ->> 'id', recording ->> 'source',
      (recording ->> 'durationMs')::integer, public.sung_line_count(song));
  end if;

  -- The other kinds change an approved song; an unknown and a hidden song get the
  -- same answer, as in submit_report.
  select s.version into current_version
  from public.songs s
  where s.id = song_id and s.status = 'approved';
  if current_version is null then
    return 'unknown_song';
  end if;

  if kind = 'edit_lyrics' then
    if base_version is null or base_version < 1 or base_version > current_version then
      return 'bad_base_version';
    end if;
    if song is null then
      return 'missing_song';
    end if;
    if recordings is not null or timings is not null
       or (song ->> 'id') is distinct from song_id then
      return 'bad_payload';
    end if;
    return public.song_payload_error(song);
  end if;

  if base_version is not null then
    return 'bad_base_version';
  end if;
  if song is not null then
    return 'bad_payload';
  end if;

  if kind = 'recording' then
    if recording is null then
      return 'missing_recording';
    end if;
    error := public.recording_payload_error(recording, song_id);
    if error is not null then
      return error;
    end if;
    if exists (select 1 from public.recordings r where r.id = recording ->> 'id') then
      return 'bad_recording';
    end if;
    if timings -> 0 is null then
      return null;
    end if;
    return public.timing_payload_error(
      timings -> 0, recording ->> 'id', recording ->> 'source',
      (recording ->> 'durationMs')::integer,
      public.sung_line_count(public.song_document(song_id) -> 'song'));
  end if;

  -- sync_timing
  if recordings is not null then
    return 'bad_payload';
  end if;
  if timings -> 0 is null then
    return 'missing_timing';
  end if;
  select * into stored
  from public.recordings r
  where r.id = timings -> 0 ->> 'recordingId' and r.song_id = contribution_error.song_id;
  if stored.id is null then
    return 'unknown_recording';
  end if;
  return public.timing_payload_error(
    timings -> 0, stored.id, public.recording_source_name(stored.source),
    stored.duration_ms,
    public.sung_line_count(public.song_document(song_id) -> 'song'));
end
$$;

revoke all on function public.contribution_error from public, anon, authenticated;

-- Submitting -------------------------------------------------------------------

-- Raises the error for [payload] as a [kind] contribution, if it breaks a rule.
create function public.check_contribution(
  kind public.contribution_kind,
  song_id text,
  base_version integer,
  payload jsonb
)
returns void
language plpgsql
stable
set search_path = ''
as $$
declare
  error text;
begin
  if octet_length(payload::text) > 262144 then
    raise exception 'payload_too_large' using errcode = '54000';
  end if;
  error := public.contribution_error(kind, song_id, base_version, payload);
  if error is not null then
    raise exception '%', error using errcode = '22023';
  end if;
end
$$;

revoke all on function public.check_contribution from public, anon, authenticated;

-- Submits a contribution for the signed-in user; returns its id.
create function public.submit_contribution(
  kind public.contribution_kind,
  payload jsonb,
  song_id text default null,
  base_version integer default null
)
returns uuid
language plpgsql
security definer
set search_path = ''
as $$
declare
  author uuid := auth.uid();
  contribution_id uuid;
begin
  if author is null then
    raise exception 'not_signed_in' using errcode = '28000';
  end if;
  perform public.check_contribution(kind, song_id, base_version, payload);

  if (
    select count(*) from public.contributions c
    where c.author_id = author and c.status in ('pending', 'changes_requested')
  ) >= 20 then
    raise exception 'too_many_open' using errcode = 'PT429';
  end if;
  if (
    select count(*) from public.contributions c
    where c.author_id = author and c.created_at > now() - interval '24 hours'
  ) >= 30 then
    raise exception 'too_many_today' using errcode = 'PT429';
  end if;

  insert into public.contributions (song_id, author_id, kind, payload, base_version)
  values (submit_contribution.song_id, author, submit_contribution.kind,
    submit_contribution.payload, submit_contribution.base_version)
  returning id into contribution_id;
  return contribution_id;
end
$$;

revoke all on function public.submit_contribution from public, anon;
grant execute on function public.submit_contribution to authenticated;

-- Replaces the payload of the signed-in user's contribution [id] that a
-- moderator sent back, and sends it for review again; returns its revision.
-- The moderator's note stays until the next review.
create function public.resubmit_contribution(id uuid, payload jsonb)
returns integer
language plpgsql
security definer
set search_path = ''
as $$
declare
  author uuid := auth.uid();
  target public.contributions;
  new_revision integer;
begin
  if author is null then
    raise exception 'not_signed_in' using errcode = '28000';
  end if;
  select * into target
  from public.contributions c
  where c.id = resubmit_contribution.id
  for update;
  if target.id is null or target.author_id is distinct from author
     or target.status <> 'changes_requested' then
    raise exception 'not_editable' using errcode = '22023';
  end if;
  perform public.check_contribution(target.kind, target.song_id, target.base_version, payload);

  update public.contributions c
  set payload = resubmit_contribution.payload,
      status = 'pending',
      submitted_at = now(),
      revision = c.revision + 1
  where c.id = target.id
  returning c.revision into new_revision;
  return new_revision;
end
$$;

revoke all on function public.resubmit_contribution from public, anon;
grant execute on function public.resubmit_contribution to authenticated;
