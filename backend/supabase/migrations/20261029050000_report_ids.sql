-- Reports stored once (intent 004, bolt 028, story 009).
--
-- The app gives each report a random ID. A report whose answer was lost (a
-- timeout) is sent again from the app's queue with the same ID; this install's
-- second copy is answered with the first one's id, stored nothing and not
-- counted for the daily limit.

alter table public.reports add column client_id uuid;

create unique index reports_install_hash_client_id_key
  on public.reports (install_hash, client_id)
  where client_id is not null;

drop function public.submit_report(public.slug, public.report_reason, text, public.slug, text);

create function public.submit_report(
  song_id public.slug,
  reason public.report_reason,
  install_id text,
  recording_id public.slug default null,
  note text default null,
  report_id uuid default null
)
returns uuid
language plpgsql
security definer
set search_path = ''
as $$
declare
  hash text;
  clean_note text := nullif(trim(note), '');
  stored_id uuid;
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

  -- A repeat: before the limit, so it is neither refused nor counted.
  if report_id is not null then
    select r.id into stored_id from public.reports r
    where r.install_hash = hash and r.client_id = report_id;
    if found then
      return stored_id;
    end if;
  end if;

  if (
    select count(*) from public.reports r
    where r.install_hash = hash and r.created_at > now() - interval '24 hours'
  ) >= 5 then
    -- PostgREST answers PTxxx codes with that HTTP status.
    raise exception 'Too many reports today' using errcode = 'PT429';
  end if;

  insert into public.reports (song_id, recording_id, reason, note, install_hash, client_id)
  values (submit_report.song_id, submit_report.recording_id, reason, clean_note, hash, report_id)
  on conflict (install_hash, client_id) where client_id is not null do nothing
  returning id into stored_id;
  if stored_id is null then
    -- Two copies at once: the other one was stored first.
    select r.id into stored_id from public.reports r
    where r.install_hash = hash and r.client_id = report_id;
  end if;
  return stored_id;
end
$$;

revoke all on function public.submit_report from public;
grant execute on function public.submit_report to anon, authenticated;
