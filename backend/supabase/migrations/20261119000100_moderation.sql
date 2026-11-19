-- Moderation for the admin website (intent 008, bolt 054).
--
-- Moderators read and close listeners' reports (story 001), and find, hide and
-- restore songs (story 002). Every function checks the role (require_moderator).
--
-- Errors, raised with the code as the message:
--   28000  not_signed_in
--   42501  not_moderator
--   22023  unknown_report, bad_status, unknown_song

-- Restoring a hidden song keeps when it was first approved.
create or replace function public.songs_before_update()
returns trigger
language plpgsql
as $$
begin
  if (new.title, new.transliteration, new.artist, new.album)
      is distinct from (old.title, old.transliteration, old.artist, old.album)
     and new.version = old.version then
    new.version := old.version + 1;
  end if;
  if new.status = 'approved' and old.status is distinct from 'approved'
     and (old.status is distinct from 'hidden' or old.approved_at is null) then
    new.approved_at := now();
  end if;
  new.updated_at := now();
  return new;
end
$$;

-- Reports with [only_status], newest first, at most [max_rows] from [skip]. The
-- install hash stays on the server.
create function public.moderator_reports(
  only_status public.report_status default 'open',
  max_rows integer default 100,
  skip integer default 0
)
returns table (
  id uuid,
  song_id text,
  song_title text,
  recording_id text,
  reason public.report_reason,
  note text,
  status public.report_status,
  created_at timestamptz
)
language plpgsql
stable
security definer
set search_path = ''
as $$
begin
  perform public.require_moderator();
  return query
  select r.id, r.song_id::text, s.title, r.recording_id::text, r.reason, r.note,
    r.status, r.created_at
  from public.reports r
  left join public.songs s on s.id = r.song_id
  where only_status is null or r.status = only_status
  order by r.created_at desc, r.id
  limit greatest(least(max_rows, 500), 0) offset greatest(skip, 0);
end
$$;

revoke all on function public.moderator_reports from public, anon;
grant execute on function public.moderator_reports to authenticated;

-- Marks report [id] resolved or dismissed (or changes which).
create function public.resolve_report(id uuid, status public.report_status)
returns void
language plpgsql
security definer
set search_path = ''
as $$
begin
  perform public.require_moderator();
  if status is null or status = 'open' then
    raise exception 'bad_status' using errcode = '22023';
  end if;
  update public.reports r set status = resolve_report.status
  where r.id = resolve_report.id;
  if not found then
    raise exception 'unknown_report' using errcode = '22023';
  end if;
end
$$;

revoke all on function public.resolve_report from public, anon;
grant execute on function public.resolve_report to authenticated;

-- Approved and hidden songs whose id, title, transliteration or artist contain
-- [query] (any case; all when empty), by title, at most [max_rows] from [skip].
create function public.moderator_songs(
  query text default null,
  max_rows integer default 50,
  skip integer default 0
)
returns table (
  id text,
  title text,
  artist text,
  status public.song_status,
  version integer,
  line_count integer,
  updated_at timestamptz
)
language plpgsql
stable
security definer
set search_path = ''
as $$
declare
  needle text := lower(nullif(btrim(query), ''));
begin
  perform public.require_moderator();
  return query
  select s.id::text, s.title, s.artist, s.status, s.version,
    (select count(*)::integer from public.lines l where l.song_id = s.id),
    s.updated_at
  from public.songs s
  where s.status in ('approved', 'hidden')
    and (needle is null
      or strpos(lower(concat_ws(' ', s.id, s.title, s.transliteration, s.artist)), needle) > 0)
  order by lower(s.title), s.id collate "C"
  limit greatest(least(max_rows, 200), 0) offset greatest(skip, 0);
end
$$;

revoke all on function public.moderator_songs from public, anon;
grant execute on function public.moderator_songs to authenticated;

-- Hides ([hidden]) or restores approved song [id]. Returns its status.
create function public.set_song_hidden(id text, hidden boolean)
returns public.song_status
language plpgsql
security definer
set search_path = ''
as $$
declare
  result public.song_status;
begin
  perform public.require_moderator();
  if hidden is null then
    raise exception 'bad_status' using errcode = '22023';
  end if;
  update public.songs s
  set status = case when hidden then 'hidden' else 'approved' end::public.song_status
  where s.id = set_song_hidden.id and s.status in ('approved', 'hidden')
  returning s.status into result;
  if result is null then
    raise exception 'unknown_song' using errcode = '22023';
  end if;
  return result;
end
$$;

revoke all on function public.set_song_hidden from public, anon;
grant execute on function public.set_song_hidden to authenticated;

-- The document of approved or hidden song [id], or null.
create function public.moderator_song(id text)
returns jsonb
language plpgsql
stable
security definer
set search_path = ''
as $$
begin
  perform public.require_moderator();
  return (
    select public.song_document(s.id)
    from public.songs s
    where s.id = moderator_song.id and s.status in ('approved', 'hidden')
  );
end
$$;

revoke all on function public.moderator_song from public, anon;
grant execute on function public.moderator_song to authenticated;
