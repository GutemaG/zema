-- Catalog schema (intent 004, bolt 018).
--
-- Listeners read approved songs; contributions and roles exist for intents 005/006
-- but nothing writes them yet. Row Level Security is on for every table with no
-- policies, so the API exposes nothing until the read rules (bolt 019) are added.

create type public.song_status as enum ('draft', 'approved', 'rejected');
create type public.section_kind as enum ('verse', 'chorus', 'bridge', 'other');
create type public.recording_source as enum ('bundled', 'local_file', 'youtube', 'telegram');
create type public.report_reason as enum ('wrong_words', 'wrong_timing', 'wrong_song', 'other');
create type public.report_status as enum ('open', 'resolved', 'dismissed');
create type public.app_role as enum ('contributor', 'moderator', 'admin');
create type public.contribution_kind as enum ('new_song', 'edit_lyrics', 'sync_timing');
create type public.contribution_status as enum ('pending', 'approved', 'changes_requested', 'rejected');

-- Stable text IDs ("selam-lezih-bet"), so links saved on phones keep working.
create domain public.slug as text
  check (value ~ '^[a-z0-9]+(-[a-z0-9]+)*$' and length(value) <= 120);

create table public.songs (
  id public.slug primary key,
  title text not null check (length(trim(title)) > 0),
  transliteration text,
  artist text,
  album text,
  status public.song_status not null default 'draft',
  -- Increases whenever the song's text, sections, recordings or timings change, so
  -- phones know their cached copy is stale.
  version integer not null default 1,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  approved_at timestamptz
);

create table public.sections (
  song_id public.slug not null references public.songs (id) on delete cascade,
  id text not null check (length(id) > 0),
  kind public.section_kind not null,
  position integer not null check (position >= 0),
  primary key (song_id, id),
  unique (song_id, position)
);

create table public.lines (
  song_id public.slug not null,
  section_id text not null,
  position integer not null check (position >= 0),
  text text not null check (length(trim(text)) > 0),
  transliteration text,
  primary key (song_id, section_id, position),
  foreign key (song_id, section_id)
    references public.sections (song_id, id) on delete cascade
);

-- The sung order of sections; empty means each section once, as written.
create table public.play_order (
  song_id public.slug not null,
  position integer not null check (position >= 0),
  section_id text not null,
  primary key (song_id, position),
  foreign key (song_id, section_id)
    references public.sections (song_id, id) on delete cascade
);

create table public.recordings (
  id public.slug primary key,
  song_id public.slug not null references public.songs (id) on delete cascade,
  source public.recording_source not null,
  artist text,
  duration_ms integer check (duration_ms > 0),
  -- Positive shows lines later, as in zema_core's Recording.offset.
  offset_ms integer not null default 0,
  created_at timestamptz not null default now()
);

create index recordings_song_id_idx on public.recordings (song_id);

-- Whether [starts] is non-empty, non-negative and never goes backwards.
create function public.is_valid_timing(starts integer[])
returns boolean
language sql
immutable
as $$
  select coalesce(array_length(starts, 1), 0) > 0
    and not exists (
      select 1
      from unnest(starts) with ordinality as s(ms, i)
      where s.ms < 0 or (s.i > 1 and s.ms < starts[s.i - 1])
    )
$$;

create table public.sync_timings (
  recording_id public.slug primary key
    references public.recordings (id) on delete cascade,
  starts_ms integer[] not null check (public.is_valid_timing(starts_ms))
);

create table public.reports (
  id uuid primary key default gen_random_uuid(),
  song_id public.slug references public.songs (id) on delete set null,
  recording_id public.slug references public.recordings (id) on delete set null,
  reason public.report_reason not null,
  note text check (length(note) <= 500),
  -- A hash of the app's random install ID, for rate limiting; never the raw ID.
  install_hash text not null,
  status public.report_status not null default 'open',
  created_at timestamptz not null default now()
);

create index reports_install_hash_created_at_idx
  on public.reports (install_hash, created_at);

create table public.user_roles (
  user_id uuid not null references auth.users (id) on delete cascade,
  role public.app_role not null,
  created_at timestamptz not null default now(),
  primary key (user_id, role)
);

create table public.contributions (
  id uuid primary key default gen_random_uuid(),
  song_id public.slug references public.songs (id) on delete set null,
  author_id uuid references auth.users (id) on delete set null,
  kind public.contribution_kind not null,
  payload jsonb not null,
  status public.contribution_status not null default 'pending',
  review_note text,
  reviewer_id uuid references auth.users (id) on delete set null,
  created_at timestamptz not null default now(),
  reviewed_at timestamptz
);

create index contributions_status_idx on public.contributions (status, created_at);

-- Version bumps ---------------------------------------------------------------

create function public.bump_song_version(target public.slug)
returns void
language sql
as $$
  update public.songs
  set version = version + 1, updated_at = now()
  where id = target
$$;

-- For tables with a song_id column.
create function public.bump_song_version_from_child()
returns trigger
language plpgsql
as $$
begin
  if tg_op in ('UPDATE', 'DELETE') then
    perform public.bump_song_version(old.song_id);
  end if;
  if tg_op in ('INSERT', 'UPDATE') and (tg_op = 'INSERT' or new.song_id is distinct from old.song_id) then
    perform public.bump_song_version(new.song_id);
  end if;
  return null;
end
$$;

create function public.bump_song_version_from_timing()
returns trigger
language plpgsql
as $$
begin
  perform public.bump_song_version(r.song_id)
  from public.recordings r
  where r.id = coalesce(new.recording_id, old.recording_id);
  return null;
end
$$;

create trigger sections_bump_version after insert or update or delete on public.sections
  for each row execute function public.bump_song_version_from_child();
create trigger lines_bump_version after insert or update or delete on public.lines
  for each row execute function public.bump_song_version_from_child();
create trigger play_order_bump_version after insert or update or delete on public.play_order
  for each row execute function public.bump_song_version_from_child();
create trigger recordings_bump_version after insert or update or delete on public.recordings
  for each row execute function public.bump_song_version_from_child();
create trigger sync_timings_bump_version after insert or update or delete on public.sync_timings
  for each row execute function public.bump_song_version_from_timing();

-- A song's own text changing bumps its version; approval records when.
create function public.songs_before_update()
returns trigger
language plpgsql
as $$
begin
  if (new.title, new.transliteration, new.artist, new.album)
      is distinct from (old.title, old.transliteration, old.artist, old.album)
     and new.version = old.version then
    new.version := old.version + 1;
  end if;
  if new.status = 'approved' and old.status is distinct from 'approved' then
    new.approved_at := now();
  end if;
  new.updated_at := now();
  return new;
end
$$;

create trigger songs_before_update before update on public.songs
  for each row execute function public.songs_before_update();

create function public.songs_before_insert()
returns trigger
language plpgsql
as $$
begin
  if new.status = 'approved' and new.approved_at is null then
    new.approved_at := now();
  end if;
  return new;
end
$$;

create trigger songs_before_insert before insert on public.songs
  for each row execute function public.songs_before_insert();

-- Row Level Security: on everywhere, no policies yet (bolt 019 adds reads). ---

alter table public.songs enable row level security;
alter table public.sections enable row level security;
alter table public.lines enable row level security;
alter table public.play_order enable row level security;
alter table public.recordings enable row level security;
alter table public.sync_timings enable row level security;
alter table public.reports enable row level security;
alter table public.user_roles enable row level security;
alter table public.contributions enable row level security;
