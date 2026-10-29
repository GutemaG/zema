-- Read rules (intent 004, bolt 019, story 002).
--
-- Anyone may read approved songs and their parts; nothing else is readable, and no
-- one writes through the API (reports go through submit_report). Write grants are
-- revoked as well, so a missing policy is not the only guard.

create index songs_status_idx on public.songs (status);

create function public.is_song_approved(target public.slug)
returns boolean
language sql
stable
as $$
  select exists (select 1 from public.songs where id = target and status = 'approved')
$$;

create policy "Approved songs are public" on public.songs
  for select to anon, authenticated
  using (status = 'approved');

create policy "Sections of approved songs are public" on public.sections
  for select to anon, authenticated
  using (public.is_song_approved(song_id));

create policy "Lines of approved songs are public" on public.lines
  for select to anon, authenticated
  using (public.is_song_approved(song_id));

create policy "Play order of approved songs is public" on public.play_order
  for select to anon, authenticated
  using (public.is_song_approved(song_id));

create policy "Recordings of approved songs are public" on public.recordings
  for select to anon, authenticated
  using (public.is_song_approved(song_id));

create policy "Timings of approved songs are public" on public.sync_timings
  for select to anon, authenticated
  using (
    exists (
      select 1 from public.recordings r
      where r.id = recording_id and public.is_song_approved(r.song_id)
    )
  );

-- reports, contributions, user_roles: no policies, so nothing is readable.

revoke insert, update, delete, truncate on all tables in schema public
  from anon, authenticated;
-- Tables created by later migrations get the same default.
alter default privileges in schema public
  revoke insert, update, delete, truncate on tables from anon, authenticated;
