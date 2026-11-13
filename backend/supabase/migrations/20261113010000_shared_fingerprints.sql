-- Fingerprints sent from phones (intent 009, FR-2).
--
-- A contribution with a file recording carries its fingerprint
-- (attach_fingerprint), published when a moderator approves the contribution.
-- Listeners who opt in share the fingerprints of library files linked to a
-- catalog recording that has none (share_fingerprint): published at once when a
-- second install sends one that lines up with it, otherwise when a moderator
-- approves it (moderator_fingerprints, review_fingerprint). Only hashes are
-- sent, as in the seed tool; until published they are kept here, out of the API.
--
-- Errors, raised with the code as the message:
--   28000  not_signed_in
--   42501  not_moderator
--   22023  not_editable, bad_recording, bad_fingerprint, unknown_fingerprint,
--          invalid install ID
--   PT429  too_many_today

create table public.pending_fingerprints (
  id uuid primary key default gen_random_uuid(),
  recording_id public.slug not null,
  contribution_id uuid unique references public.contributions (id) on delete cascade,
  -- A hash of the sending install's ID, for library fingerprints.
  install_key text,
  version smallint not null check (version > 0),
  frame_count integer not null check (frame_count > 0),
  hashes integer[] not null,
  frames integer[] not null,
  created_at timestamptz not null default clock_timestamp(),
  check ((contribution_id is null) <> (install_key is null)),
  check (cardinality(hashes) = cardinality(frames))
);

create unique index pending_fingerprints_install_idx
  on public.pending_fingerprints (recording_id, install_key)
  where install_key is not null;

alter table public.pending_fingerprints enable row level security;

-- Frames a second, as zema_core's fingerprintSampleRate / fingerprintHop.
create function public.fingerprint_frames_per_second()
returns numeric
language sql
immutable
as $$ select 11025 / 256.0 $$;

-- The first rule a sent fingerprint breaks, or null: at least 100 and at most
-- 120,000 hashes (20 minutes at the catalog density), each a 24-bit hash at a
-- frame inside the recording, and as long as the recording ([duration_ms],
-- when known) within 3 s or 5 %.
create function public.fingerprint_error(
  version integer,
  frame_count integer,
  hashes integer[],
  frames integer[],
  duration_ms integer
)
returns text
language sql
immutable
set search_path = ''
as $$
  select case
    when version is null or version not between 1 and 32767
      or frame_count is null or frame_count not between 1 and 52000
      or hashes is null or frames is null
      or cardinality(hashes) <> cardinality(frames)
      or cardinality(hashes) not between 100 and 120000
      or exists (
        select 1 from unnest(hashes, frames) as t(h, f)
        where t.h is null or t.h not between 0 and 16777215
          or t.f is null or t.f not between 0 and frame_count - 1
      )
      or (duration_ms is not null and abs(
        frame_count * 1000 / public.fingerprint_frames_per_second() - duration_ms
      ) > greatest(3000, duration_ms * 0.05))
    then 'bad_fingerprint'
  end
$$;

revoke all on function public.fingerprint_error from public, anon, authenticated;

-- Contributions ----------------------------------------------------------------

-- Attaches the fingerprint of the file recording in the signed-in user's
-- contribution [contribution] (pending, or sent back for changes), replacing
-- one attached before.
create function public.attach_fingerprint(
  contribution uuid,
  version integer,
  frame_count integer,
  hashes integer[],
  frames integer[]
)
returns void
language plpgsql
security definer
set search_path = ''
as $$
declare
  author uuid := auth.uid();
  target public.contributions;
  recording jsonb;
begin
  if author is null then
    raise exception 'not_signed_in' using errcode = '28000';
  end if;
  select * into target from public.contributions c where c.id = contribution;
  if target.id is null or target.author_id is distinct from author
     or target.status not in ('pending', 'changes_requested') then
    raise exception 'not_editable' using errcode = '22023';
  end if;
  recording := target.payload -> 'recordings' -> 0;
  if recording is null or recording ->> 'source' = 'youtube' then
    raise exception 'bad_recording' using errcode = '22023';
  end if;
  if public.fingerprint_error(version, frame_count, hashes, frames,
      (recording ->> 'durationMs')::integer) is not null then
    raise exception 'bad_fingerprint' using errcode = '22023';
  end if;
  insert into public.pending_fingerprints
    (recording_id, contribution_id, version, frame_count, hashes, frames)
  values (recording ->> 'id', target.id, version, frame_count, hashes, frames)
  on conflict (contribution_id) do update set
    recording_id = excluded.recording_id,
    version = excluded.version,
    frame_count = excluded.frame_count,
    hashes = excluded.hashes,
    frames = excluded.frames,
    created_at = clock_timestamp();
end
$$;

revoke all on function public.attach_fingerprint from public, anon;
grant execute on function public.attach_fingerprint to authenticated;

-- Publishes a pending fingerprint as [recording]'s.
create function public.publish_pending_fingerprint(
  pending public.pending_fingerprints,
  recording text
)
returns void
language sql
set search_path = ''
as $$
  select public.put_fingerprint(recording, pending.version, pending.frame_count,
    pending.hashes, pending.frames);
  delete from public.pending_fingerprints p
  where p.recording_id = recording and p.install_key is not null;
$$;

revoke all on function public.publish_pending_fingerprint from public, anon, authenticated;

-- A contribution's fingerprint goes public with its recording when the
-- contribution is approved, and away when it is rejected.
create function public.contribution_fingerprint_reviewed()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
declare
  pending public.pending_fingerprints;
  recording text := new.payload -> 'recordings' -> 0 ->> 'id';
begin
  select * into pending from public.pending_fingerprints p where p.contribution_id = new.id;
  if pending.id is null then
    return null;
  end if;
  if new.status = 'approved'
     and exists (select 1 from public.recordings r where r.id = recording) then
    perform public.publish_pending_fingerprint(pending, recording);
  end if;
  if new.status in ('approved', 'rejected') then
    delete from public.pending_fingerprints p where p.id = pending.id;
  end if;
  return null;
end
$$;

revoke all on function public.contribution_fingerprint_reviewed from public, anon, authenticated;

create trigger contribution_fingerprint_reviewed
  after update of status on public.contributions
  for each row
  when (old.status is distinct from new.status)
  execute function public.contribution_fingerprint_reviewed();

-- Libraries ----------------------------------------------------------------------

-- Of [ids], the recordings of approved songs with no fingerprint of [version]:
-- the ones a library file's fingerprint can help.
create function public.missing_fingerprints(version integer, ids text[])
returns setof public.slug
language sql
stable
security definer
set search_path = ''
as $$
  select r.id
  from public.recordings r
  join public.songs s on s.id = r.song_id and s.status = 'approved'
  where r.id = any (ids[1:200])
    and not exists (
      select 1 from public.recording_fingerprints fp
      where fp.recording_id = r.id and fp.version = missing_fingerprints.version
    )
  order by r.id
$$;

revoke all on function public.missing_fingerprints from public;
grant execute on function public.missing_fingerprints to anon, authenticated;

-- How well fingerprints a and b line up as the same audio: the most hashes
-- that match within a frame of each other at a shift of at most 4 frames
-- (0.1 s), as a share of the smaller one's hashes.
create function public.fingerprint_agreement(
  a_hashes integer[], a_frames integer[], b_hashes integer[], b_frames integer[]
)
returns numeric
language sql
immutable
set search_path = ''
as $$
  with a as (select * from unnest(a_hashes, a_frames) as t(h, f)),
  b as (select * from unnest(b_hashes, b_frames) as t(h, f)),
  votes as (
    select b.f - a.f as shift, count(*) as n
    from a join b on b.h = a.h
    where abs(b.f - a.f) <= 5
    group by b.f - a.f
  )
  select coalesce(max((
    select sum(v2.n) from votes v2 where abs(v2.shift - v1.shift) <= 1
  )), 0) / greatest(1, least(cardinality(a_hashes), cardinality(b_hashes)))
  from votes v1
  where abs(v1.shift) <= 4
$$;

revoke all on function public.fingerprint_agreement from public, anon, authenticated;

-- Least agreement for two installs' fingerprints to publish themselves.
create function public.fingerprint_min_agreement()
returns numeric
language sql
immutable
as $$ select 0.2 $$;

-- Shares the fingerprint of a library file linked to [recording] from install
-- [install_id] (at most 30 a day): 'published' when it lines up with one another
-- install sent, 'pending' until then or a moderator approves it, and
-- 'not_needed' when the recording has a fingerprint or isn't in the catalog.
create function public.share_fingerprint(
  recording text,
  version integer,
  frame_count integer,
  hashes integer[],
  frames integer[],
  install_id text
)
returns text
language plpgsql
security definer
set search_path = ''
as $$
declare
  sender text;
  target public.recordings;
  mine public.pending_fingerprints;
  other public.pending_fingerprints;
begin
  if install_id is null or length(install_id) not between 8 and 64 then
    raise exception 'Invalid install ID' using errcode = '22023';
  end if;
  sender := encode(extensions.digest(install_id, 'sha256'), 'hex');
  if not public.count_identify('share:' || sender, 30) then
    raise exception 'too_many_today' using errcode = 'PT429';
  end if;
  select r.* into target
  from public.recordings r
  join public.songs s on s.id = r.song_id and s.status = 'approved'
  where r.id = recording;
  if target.id is null or exists (
    select 1 from public.recording_fingerprints fp
    where fp.recording_id = target.id and fp.version = share_fingerprint.version
  ) then
    return 'not_needed';
  end if;
  if public.fingerprint_error(version, frame_count, hashes, frames, target.duration_ms)
      is not null then
    raise exception 'bad_fingerprint' using errcode = '22023';
  end if;

  insert into public.pending_fingerprints
    (recording_id, install_key, version, frame_count, hashes, frames)
  values (target.id, sender, version, frame_count, hashes, frames)
  on conflict (recording_id, install_key) where install_key is not null do update set
    version = excluded.version,
    frame_count = excluded.frame_count,
    hashes = excluded.hashes,
    frames = excluded.frames,
    created_at = clock_timestamp()
  returning * into mine;

  for other in
    select * from public.pending_fingerprints p
    where p.recording_id = target.id and p.install_key is not null
      and p.install_key <> mine.install_key and p.version = mine.version
    order by p.created_at
  loop
    if public.fingerprint_agreement(other.hashes, other.frames, mine.hashes, mine.frames)
        >= public.fingerprint_min_agreement() then
      perform public.publish_pending_fingerprint(other, target.id);
      return 'published';
    end if;
  end loop;
  return 'pending';
end
$$;

revoke all on function public.share_fingerprint from public;
grant execute on function public.share_fingerprint to anon, authenticated;

-- Library fingerprints waiting for a moderator, oldest first, with the song
-- and recording they are for and how many installs sent one.
create function public.moderator_fingerprints()
returns table (
  id uuid,
  recording_id text,
  song_id text,
  song_title text,
  recording_artist text,
  duration_ms integer,
  frame_count integer,
  hash_count integer,
  installs integer,
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
  select p.id, p.recording_id::text, s.id::text, s.title, r.artist, r.duration_ms,
    p.frame_count, cardinality(p.hashes),
    (select count(*)::integer from public.pending_fingerprints o
      where o.recording_id = p.recording_id and o.install_key is not null),
    p.created_at
  from public.pending_fingerprints p
  join public.recordings r on r.id = p.recording_id
  join public.songs s on s.id = r.song_id
  where p.install_key is not null
  order by p.created_at, p.id;
end
$$;

revoke all on function public.moderator_fingerprints from public, anon;
grant execute on function public.moderator_fingerprints to authenticated;

-- Publishes ([approve]) or drops the library fingerprint [id].
create function public.review_fingerprint(id uuid, approve boolean)
returns void
language plpgsql
security definer
set search_path = ''
as $$
declare
  target public.pending_fingerprints;
begin
  perform public.require_moderator();
  select * into target
  from public.pending_fingerprints p
  where p.id = review_fingerprint.id and p.install_key is not null
  for update;
  if target.id is null then
    raise exception 'unknown_fingerprint' using errcode = '22023';
  end if;
  if approve then
    perform public.publish_pending_fingerprint(target, target.recording_id);
  else
    delete from public.pending_fingerprints p where p.id = target.id;
  end if;
end
$$;

revoke all on function public.review_fingerprint from public, anon;
grant execute on function public.review_fingerprint to authenticated;
