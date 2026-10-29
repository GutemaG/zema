-- The song index phones keep (bolt 022): every approved song, without lyrics, in
-- one call. "synced" says whether any recording has a timing; "version" tells a
-- phone when its cached copy is stale.
create function public.song_index()
returns table (
  id text,
  title text,
  transliteration text,
  artist text,
  album text,
  synced boolean,
  version integer,
  approved_at timestamptz
)
language sql
stable
security definer
set search_path = ''
as $$
  select
    s.id, s.title, s.transliteration, s.artist, s.album,
    exists (
      select 1
      from public.recordings r
      join public.sync_timings t on t.recording_id = r.id
      where r.song_id = s.id
    ),
    s.version, s.approved_at
  from public.songs s
  where s.status = 'approved'
  order by s.id collate "C"
$$;

revoke all on function public.song_index from public;
grant execute on function public.song_index to anon, authenticated;
