-- One private backup per user (intent 005, bolt 030, story 003).
--
-- The app's library data and settings as one JSON document. Users read only their own
-- backup; writes go through save_backup, which always writes the caller's row and sets
-- the time on the server.

create table public.backups (
  user_id uuid primary key references auth.users (id) on delete cascade,
  format int not null check (format >= 1),
  document jsonb not null check (jsonb_typeof(document) = 'object'),
  size_bytes int generated always as (octet_length(document::text)) stored
    check (size_bytes <= 2097152),
  device text check (char_length(device) <= 100),
  updated_at timestamptz not null default now()
);

alter table public.backups enable row level security;

create policy "Users read their own backup" on public.backups
  for select to authenticated
  using (user_id = auth.uid());

-- Saves the caller's backup, replacing the previous one, and returns its time.
create function public.save_backup(document jsonb, format int, device text default null)
returns timestamptz
language plpgsql
security definer
set search_path = ''
as $$
declare
  saved_at timestamptz;
begin
  if auth.uid() is null then
    raise exception 'Not signed in' using errcode = '28000';
  end if;
  if document is null or jsonb_typeof(document) <> 'object' then
    raise exception 'Backup must be a JSON object' using errcode = '22023';
  end if;
  if format is null or format < 1 then
    raise exception 'Invalid backup format' using errcode = '22023';
  end if;
  if char_length(device) > 100 then
    raise exception 'Device name too long' using errcode = '22023';
  end if;
  if octet_length(document::text) > 2097152 then
    raise exception 'Backup too large' using errcode = '54000';
  end if;

  insert into public.backups as b (user_id, format, document, device, updated_at)
  values (auth.uid(), save_backup.format, save_backup.document, nullif(btrim(save_backup.device), ''), now())
  on conflict (user_id) do update
    set format = excluded.format,
        document = excluded.document,
        device = excluded.device,
        updated_at = excluded.updated_at
  returning b.updated_at into saved_at;

  return saved_at;
end;
$$;

revoke all on function public.save_backup from public, anon;
grant execute on function public.save_backup to authenticated;
