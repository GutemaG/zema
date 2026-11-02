-- Reviewing contributions (intent 006, bolt 040, story 002).
--
-- Moderators (the moderator or admin role) read the queue of other users'
-- pending contributions and approve, request changes or reject them. Approval
-- publishes the contribution first (publish_contribution, bolt 041), in the same
-- transaction. The owner grants the role with set_moderator, which only the
-- server can run (backend/scripts/moderator.sh).
--
-- Errors, raised with the code as the message (see bolt 039's list):
--   28000  not_signed_in
--   42501  not_moderator, own_contribution
--   PT409  already_reviewed
--   22023  unknown_contribution, bad_decision, note_required, note_too_long

create function public.is_moderator(user_id uuid)
returns boolean
language sql
stable
set search_path = ''
as $$
  select exists (
    select 1 from public.user_roles r
    where r.user_id = is_moderator.user_id and r.role in ('moderator', 'admin')
  )
$$;

-- Raises unless the caller is a signed-in moderator.
create function public.require_moderator()
returns uuid
language plpgsql
stable
set search_path = ''
as $$
declare
  caller uuid := auth.uid();
begin
  if caller is null then
    raise exception 'not_signed_in' using errcode = '28000';
  end if;
  if not public.is_moderator(caller) then
    raise exception 'not_moderator' using errcode = '42501';
  end if;
  return caller;
end
$$;

revoke all on function public.require_moderator from public, anon, authenticated;

-- Pending contributions by other users ([only_kind] when given), oldest first,
-- with what a moderator needs to review them: the author's name and the song
-- as it is now.
create function public.moderator_queue(only_kind public.contribution_kind default null)
returns table (
  id uuid,
  kind public.contribution_kind,
  song_id text,
  base_version integer,
  current_version integer,
  payload jsonb,
  revision integer,
  author_name text,
  review_note text,
  submitted_at timestamptz,
  current_document jsonb
)
language plpgsql
stable
security definer
set search_path = ''
as $$
declare
  caller uuid := public.require_moderator();
begin
  return query
  select c.id, c.kind, c.song_id::text, c.base_version, s.version, c.payload,
    c.revision, p.display_name, c.review_note, c.submitted_at,
    case when s.id is null then null else public.song_document(s.id) end
  from public.contributions c
  left join public.songs s on s.id = c.song_id
  left join public.profiles p on p.id = c.author_id
  where c.status = 'pending'
    and c.author_id is distinct from caller
    and (only_kind is null or c.kind = only_kind)
  order by c.submitted_at, c.created_at, c.id;
end
$$;

revoke all on function public.moderator_queue from public, anon;
grant execute on function public.moderator_queue to authenticated;

-- Publishes an approved contribution and returns its song's id. Replaced by
-- bolt 041; until then it publishes nothing.
create function public.publish_contribution(contribution public.contributions)
returns text
language plpgsql
set search_path = ''
as $$
begin
  return contribution.song_id;
end
$$;

revoke all on function public.publish_contribution from public, anon, authenticated;

-- Reviews pending contribution [id]: approved (published first),
-- changes_requested or rejected (both need a note). Returns the song id.
create function public.review_contribution(
  id uuid,
  decision public.contribution_status,
  note text default null
)
returns text
language plpgsql
security definer
set search_path = ''
as $$
declare
  caller uuid := public.require_moderator();
  clean_note text := nullif(btrim(note), '');
  target public.contributions;
  published text;
begin
  if decision is null or decision = 'pending' then
    raise exception 'bad_decision' using errcode = '22023';
  end if;
  if char_length(clean_note) > 1000 then
    raise exception 'note_too_long' using errcode = '22023';
  end if;
  if decision <> 'approved' and clean_note is null then
    raise exception 'note_required' using errcode = '22023';
  end if;

  select * into target
  from public.contributions c
  where c.id = review_contribution.id
  for update;
  if target.id is null then
    raise exception 'unknown_contribution' using errcode = '22023';
  end if;
  if target.author_id = caller then
    raise exception 'own_contribution' using errcode = '42501';
  end if;
  if target.status <> 'pending' then
    raise exception 'already_reviewed' using errcode = 'PT409';
  end if;

  published := target.song_id;
  if decision = 'approved' then
    published := public.publish_contribution(target);
  end if;

  update public.contributions c
  set status = decision,
      review_note = clean_note,
      reviewer_id = caller,
      reviewed_at = now(),
      song_id = published
  where c.id = target.id;
  return published;
end
$$;

revoke all on function public.review_contribution from public, anon;
grant execute on function public.review_contribution to authenticated;

-- Gives ([enabled]) or takes away the moderator role of the user with [email].
-- Returns granted, revoked or unchanged. Server only: the owner runs it with
-- backend/scripts/moderator.sh.
create function public.set_moderator(email text, enabled boolean)
returns text
language plpgsql
set search_path = ''
as $$
declare
  target uuid;
  changed integer;
begin
  select u.id into target
  from auth.users u
  where lower(u.email) = lower(btrim(set_moderator.email));
  if target is null then
    raise exception 'unknown_email' using errcode = '22023';
  end if;
  if enabled then
    insert into public.user_roles (user_id, role) values (target, 'moderator')
    on conflict do nothing;
  else
    delete from public.user_roles r where r.user_id = target and r.role = 'moderator';
  end if;
  get diagnostics changed = row_count;
  return case when changed = 0 then 'unchanged' when enabled then 'granted' else 'revoked' end;
end
$$;

revoke all on function public.set_moderator from public, anon, authenticated;
grant execute on function public.set_moderator to service_role;
