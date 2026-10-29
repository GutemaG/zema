-- Reports from listeners (intent 004, bolt 019, story 003).
--
-- The only write open to anonymous users. The reports table stays closed; this
-- function checks the input, stores a hash of the install ID (never the ID) and
-- allows at most 5 reports per install in any 24 hours.

create function public.submit_report(
  song_id public.slug,
  reason public.report_reason,
  install_id text,
  recording_id public.slug default null,
  note text default null
)
returns uuid
language plpgsql
security definer
set search_path = ''
as $$
declare
  hash text;
  clean_note text := nullif(trim(note), '');
  report_id uuid;
begin
  if install_id is null or length(install_id) not between 8 and 64 then
    raise exception 'Invalid install ID' using errcode = '22023';
  end if;
  -- Unknown and unapproved songs get the same answer, so drafts stay hidden.
  if not exists (
    select 1 from public.songs s where s.id = song_id and s.status = 'approved'
  ) then
    raise exception 'Unknown song' using errcode = '22023';
  end if;
  if recording_id is not null and not exists (
    select 1 from public.recordings r
    where r.id = recording_id and r.song_id = submit_report.song_id
  ) then
    raise exception 'Unknown recording' using errcode = '22023';
  end if;
  if length(clean_note) > 500 then
    raise exception 'Note too long' using errcode = '22023';
  end if;

  hash := encode(extensions.digest(install_id, 'sha256'), 'hex');
  if (
    select count(*) from public.reports r
    where r.install_hash = hash and r.created_at > now() - interval '24 hours'
  ) >= 5 then
    -- PostgREST answers PTxxx codes with that HTTP status.
    raise exception 'Too many reports today' using errcode = 'PT429';
  end if;

  insert into public.reports (song_id, recording_id, reason, note, install_hash)
  values (submit_report.song_id, submit_report.recording_id, reason, clean_note, hash)
  returning id into report_id;
  return report_id;
end
$$;

revoke all on function public.submit_report from public;
grant execute on function public.submit_report to anon, authenticated;
