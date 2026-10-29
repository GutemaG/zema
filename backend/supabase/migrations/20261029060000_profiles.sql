-- Profiles and roles for signed-in users (intent 005, bolt 029, story 001).
--
-- Every new auth user gets a profile (name and avatar from Google) and the
-- contributor role. Users read only their own profile and roles, and change only
-- their own display name. Roles are changed on the server only (006/008).

create table public.profiles (
  id uuid primary key references auth.users (id) on delete cascade,
  display_name text not null
    check (display_name = btrim(display_name) and char_length(display_name) between 1 and 40),
  avatar_url text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

alter table public.profiles enable row level security;

-- Trims the name, so the check refuses only empty or over-long names.
create function public.profiles_before_update()
returns trigger
language plpgsql
as $$
begin
  new.display_name := btrim(new.display_name);
  new.updated_at := now();
  return new;
end;
$$;

create trigger profiles_before_update
  before update on public.profiles
  for each row execute function public.profiles_before_update();

-- The name for a new user: Google's full name or name, else the email's local
-- part, trimmed and cut to 40 characters.
create function public.initial_display_name(meta jsonb, email text)
returns text
language sql
immutable
as $$
  select coalesce(
    nullif(left(btrim(meta ->> 'full_name'), 40), ''),
    nullif(left(btrim(meta ->> 'name'), 40), ''),
    nullif(left(btrim(split_part(coalesce(meta ->> 'email', email), '@', 1)), 40), ''),
    'Zema user'
  )
$$;

-- Runs as the owner, so it can write profiles and roles that the API roles can't.
create function public.handle_new_user()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
begin
  insert into public.profiles (id, display_name, avatar_url)
  values (
    new.id,
    btrim(public.initial_display_name(new.raw_user_meta_data, new.email)),
    coalesce(
      nullif(new.raw_user_meta_data ->> 'avatar_url', ''),
      nullif(new.raw_user_meta_data ->> 'picture', '')
    )
  )
  on conflict (id) do nothing;

  insert into public.user_roles (user_id, role)
  values (new.id, 'contributor')
  on conflict do nothing;

  return new;
end;
$$;

revoke execute on function public.handle_new_user() from public, anon, authenticated;

create trigger on_auth_user_created
  after insert on auth.users
  for each row execute function public.handle_new_user();

-- Users who signed up before this migration.
insert into public.profiles (id, display_name, avatar_url)
select
  u.id,
  btrim(public.initial_display_name(u.raw_user_meta_data, u.email)),
  coalesce(
    nullif(u.raw_user_meta_data ->> 'avatar_url', ''),
    nullif(u.raw_user_meta_data ->> 'picture', '')
  )
from auth.users u
on conflict (id) do nothing;

insert into public.user_roles (user_id, role)
select id, 'contributor' from auth.users
on conflict do nothing;

-- Policies. Writes stay revoked by default (bolt 019); the display name is the
-- only column a user may write.

create policy "Users read their own profile" on public.profiles
  for select to authenticated
  using (id = auth.uid());

create policy "Users update their own profile" on public.profiles
  for update to authenticated
  using (id = auth.uid())
  with check (id = auth.uid());

grant update (display_name) on public.profiles to authenticated;

create policy "Users read their own roles" on public.user_roles
  for select to authenticated
  using (user_id = auth.uid());
