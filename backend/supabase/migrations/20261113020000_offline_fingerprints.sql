-- The offline index on phones (intent 009, FR-4).
--
-- A fingerprint's revision goes up each time it is replaced, so phones fetch
-- only what changed; identified counts how often Listen found a recording, so
-- phones with room keep the most identified ones. offline_fingerprints lists
-- what phones can keep and get_fingerprints serves them, approved songs only.

alter table public.recording_fingerprints
  add column revision integer not null default 1 check (revision >= 1),
  add column identified integer not null default 0 check (identified >= 0);

-- As before (bolt FR-2), keeping the row so its revision goes up.
create or replace function public.put_fingerprint(
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
  insert into public.recording_fingerprints as fp
    (recording_id, version, frame_count, hash_count)
  values (target, version, frame_count, coalesce(array_length(hashes, 1), 0))
  on conflict (recording_id) do update set
    version = excluded.version,
    frame_count = excluded.frame_count,
    hash_count = excluded.hash_count,
    revision = fp.revision + 1,
    created_at = now();
  delete from public.fingerprint_hashes h where h.recording_id = target;
  insert into public.fingerprint_hashes (hash, recording_id, frame)
  select h, target, f from unnest(hashes, frames) as t(h, f);
end;
$$;

-- As before, also counting the best match's recording as identified.
create or replace function public.identify_audio(
  version integer,
  hashes integer[],
  frames integer[],
  install_id text,
  queries integer[] default null,
  max_results integer default 3
)
returns table (
  recording_id public.slug,
  song_id public.slug,
  query integer,
  shift integer,
  score integer,
  runner_up integer,
  frame_count integer
)
language plpgsql
security definer
set search_path = ''
as $$
declare
  install_key text;
  ip text;
  counted boolean := false;
begin
  if install_id is null or length(install_id) not between 8 and 64 then
    raise exception 'Invalid install ID' using errcode = '22023';
  end if;
  if coalesce(array_length(hashes, 1), 0) <> coalesce(array_length(frames, 1), 0)
    or (queries is not null
      and coalesce(array_length(queries, 1), 0) <> coalesce(array_length(hashes, 1), 0)) then
    raise exception 'hashes, frames and queries differ in length' using errcode = '22023';
  end if;
  if coalesce(array_length(hashes, 1), 0) > 20000 then
    raise exception 'At most 20000 hashes' using errcode = '22023';
  end if;
  install_key := 'install:' || encode(extensions.digest(install_id, 'sha256'), 'hex');
  ip := trim(split_part(coalesce(
    nullif(current_setting('request.headers', true), '')::json ->> 'x-forwarded-for', ''), ',', 1));
  if not public.count_identify(install_key, 300)
    or (ip <> '' and not public.count_identify(
      'ip:' || encode(extensions.digest(ip, 'sha256'), 'hex'), 2000)) then
    raise exception 'Too many lookups today' using errcode = 'PT429';
  end if;
  for recording_id, song_id, query, shift, score, runner_up, frame_count in
  with excerpt as (
    select t.h, t.f, coalesce(t.q, 0) as q
    from unnest(hashes, frames, queries) as t(h, f, q)
    where t.h is not null and t.f is not null
  ),
  candidates as (
    select fp.recording_id, r.song_id, fp.frame_count
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
    ), 0)::integer,
    c.frame_count
  from per_recording p
  join candidates c on c.recording_id = p.recording_id
  order by p.score desc, p.recording_id
  limit greatest(1, least(max_results, 10))
  loop
    if not counted then
      counted := true;
      update public.recording_fingerprints fp set identified = fp.identified + 1
      where fp.recording_id = identify_audio.recording_id;
      update public.identify_counts c set matches = c.matches + 1
      where c.key = install_key and c.day = current_date;
    end if;
    return next;
  end loop;
end;
$$;


-- The fingerprints of [version] phones can keep: approved songs' recordings,
-- most identified first.
create function public.offline_fingerprints(version integer)
returns table (
  recording_id text,
  song_id text,
  revision integer,
  hash_count integer,
  identified integer
)
language sql
stable
security definer
set search_path = ''
as $$
  select fp.recording_id, r.song_id, fp.revision, fp.hash_count, fp.identified
  from public.recording_fingerprints fp
  join public.recordings r on r.id = fp.recording_id
  join public.songs s on s.id = r.song_id and s.status = 'approved'
  where fp.version = offline_fingerprints.version
  order by fp.identified desc, fp.recording_id
$$;

revoke all on function public.offline_fingerprints from public;
grant execute on function public.offline_fingerprints to anon, authenticated;

-- The fingerprints of [version] for up to 20 of [ids], approved songs only:
-- each hash with its frame, in frame order.
create function public.get_fingerprints(version integer, ids text[])
returns table (
  recording_id text,
  revision integer,
  frame_count integer,
  hashes integer[],
  frames integer[]
)
language sql
stable
security definer
set search_path = ''
as $$
  select fp.recording_id, fp.revision, fp.frame_count,
    coalesce(array_agg(h.hash order by h.frame, h.hash)
      filter (where h.hash is not null), '{}'),
    coalesce(array_agg(h.frame order by h.frame, h.hash)
      filter (where h.hash is not null), '{}')
  from public.recording_fingerprints fp
  join public.recordings r on r.id = fp.recording_id
  join public.songs s on s.id = r.song_id and s.status = 'approved'
  left join public.fingerprint_hashes h on h.recording_id = fp.recording_id
  where fp.version = get_fingerprints.version and fp.recording_id = any (ids[1:20])
  group by fp.recording_id, fp.revision, fp.frame_count
  order by fp.recording_id
$$;

revoke all on function public.get_fingerprints from public;
grant execute on function public.get_fingerprints to anon, authenticated;
