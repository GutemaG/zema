-- Audio fingerprints of recordings (intent 009, FR-2) and the lookup by excerpt
-- (FR-3), matching zema_core's FingerprintIndex.
--
-- Only hashes are stored: pairs of spectral peaks with the frame of the first,
-- which can't be turned back into sound. Nothing here is readable through the
-- API; listeners search with identify_audio, which finds approved songs only.

create table public.recording_fingerprints (
  recording_id public.slug primary key
    references public.recordings (id) on delete cascade,
  version smallint not null check (version > 0),
  frame_count integer not null check (frame_count > 0),
  hash_count integer not null check (hash_count >= 0),
  created_at timestamptz not null default now()
);

create table public.fingerprint_hashes (
  hash integer not null check (hash between 0 and 16777215),
  recording_id public.slug not null
    references public.recording_fingerprints (recording_id) on delete cascade,
  frame integer not null check (frame >= 0)
);

create index fingerprint_hashes_hash_idx
  on public.fingerprint_hashes (hash) include (recording_id, frame);
create index fingerprint_hashes_recording_id_idx
  on public.fingerprint_hashes (recording_id);

alter table public.recording_fingerprints enable row level security;
alter table public.fingerprint_hashes enable row level security;

-- Replaces [target]'s fingerprint. For the seed tool and, later, approved
-- contributions; not callable through the API by listeners.
create function public.put_fingerprint(
  target public.slug,
  version integer,
  frame_count integer,
  hashes integer[],
  frames integer[]
)
returns void
language plpgsql
set search_path = ''
as $$
begin
  if coalesce(array_length(hashes, 1), 0) <> coalesce(array_length(frames, 1), 0) then
    raise exception 'hashes and frames differ in length' using errcode = '22023';
  end if;
  delete from public.recording_fingerprints where recording_id = target;
  insert into public.recording_fingerprints (recording_id, version, frame_count, hash_count)
  values (target, version, frame_count, coalesce(array_length(hashes, 1), 0));
  insert into public.fingerprint_hashes (hash, recording_id, frame)
  select h, target, f from unnest(hashes, frames) as t(h, f);
end;
$$;

revoke execute on function public.put_fingerprint(public.slug, integer, integer, integer[], integer[])
  from public, anon, authenticated;
grant execute on function public.put_fingerprint(public.slug, integer, integer, integer[], integer[])
  to service_role;

-- Fewest hashes that must line up at one shift, as zema_core's minimumMatchScore.
create function public.fingerprint_min_score()
returns integer
language sql
immutable
as $$ select 12 $$;

-- The approved recordings an excerpt matches, best first.
--
-- [hashes] and [frames] are the excerpt's fingerprint (zema_core's
-- AudioFingerprint, made with the query density); [queries] numbers each hash's
-- query when one excerpt is sent at several speeds (Fingerprinter.queries), and
-- each recording keeps its best query. For each recording and query, every
-- shift (recording frame minus excerpt frame) gets a vote per hash that lines
-- up there; a shift's score adds the shifts either side. [shift] is where the
-- excerpt starts in the recording, in frames; [runner_up] is the best score
-- more than 3 frames away, high when a chorus repeats.
create function public.identify_audio(
  version integer,
  hashes integer[],
  frames integer[],
  queries integer[] default null,
  max_results integer default 3
)
returns table (
  recording_id public.slug,
  song_id public.slug,
  query integer,
  shift integer,
  score integer,
  runner_up integer
)
language plpgsql
stable
security definer
set search_path = ''
as $$
begin
  if coalesce(array_length(hashes, 1), 0) <> coalesce(array_length(frames, 1), 0)
    or (queries is not null
      and coalesce(array_length(queries, 1), 0) <> coalesce(array_length(hashes, 1), 0)) then
    raise exception 'hashes, frames and queries differ in length' using errcode = '22023';
  end if;
  if coalesce(array_length(hashes, 1), 0) > 20000 then
    raise exception 'At most 20000 hashes' using errcode = '22023';
  end if;
  return query
  with excerpt as (
    select t.h, t.f, coalesce(t.q, 0) as q
    from unnest(hashes, frames, queries) as t(h, f, q)
    where t.h is not null and t.f is not null
  ),
  candidates as (
    select fp.recording_id, r.song_id
    from public.recording_fingerprints fp
    join public.recordings r on r.id = fp.recording_id
    join public.songs s on s.id = r.song_id and s.status = 'approved'
    where fp.version = identify_audio.version
  ),
  votes as (
    select fh.recording_id, e.q, fh.frame - e.f as shift, count(*)::integer as n
    from excerpt e
    join public.fingerprint_hashes fh on fh.hash = e.h
    where fh.recording_id in (select c.recording_id from candidates c)
    group by fh.recording_id, e.q, fh.frame - e.f
  ),
  scored as (
    select v.recording_id, v.q, v.shift,
      sum(v.n) over (
        partition by v.recording_id, v.q order by v.shift
        range between 1 preceding and 1 following
      )::integer as score
    from votes v
  ),
  best as (
    select distinct on (s.recording_id, s.q) s.recording_id, s.q, s.shift, s.score
    from scored s
    order by s.recording_id, s.q, s.score desc, s.shift
  ),
  per_recording as (
    select distinct on (b.recording_id) b.recording_id, b.q, b.shift, b.score
    from best b
    where b.score >= public.fingerprint_min_score()
    order by b.recording_id, b.score desc, b.q
  )
  select p.recording_id, c.song_id, p.q, p.shift, p.score,
    coalesce((
      select max(s.score) from scored s
      where s.recording_id = p.recording_id and s.q = p.q and abs(s.shift - p.shift) > 3
    ), 0)::integer
  from per_recording p
  join candidates c on c.recording_id = p.recording_id
  order by p.score desc, p.recording_id
  limit greatest(1, least(max_results, 10));
end;
$$;

revoke execute on function public.identify_audio(integer, integer[], integer[], integer[], integer)
  from public;
grant execute on function public.identify_audio(integer, integer[], integer[], integer[], integer)
  to anon, authenticated, service_role;
