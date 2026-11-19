-- Track prints (intent 013): small whole-file prints that find the song of a
-- library file whose tags don't name it, matching zema_core's TrackPrint.
--
-- A print is one 32-bit value per 46 ms of the file's first 110 s (stored
-- signed), compared by the share of differing bits at the best shift. Prints
-- belong to songs, several per song (different masters). They are published
-- by the seed tool, when two installs send matching prints for the same song,
-- or by a moderator. A print that matches another song's is held for a
-- moderator. Nothing here is readable through the API.
--
-- Errors, raised with the code as the message:
--   42501  not_moderator
--   22023  bad_print, unknown_print, invalid install ID
--   PT429  too_many_today

create table public.track_prints (
  id bigint generated always as identity primary key,
  song_id public.slug not null references public.songs (id) on delete cascade,
  version smallint not null check (version > 0),
  print integer[] not null,
  duration_ms integer not null check (duration_ms > 0),
  status text not null default 'pending' check (status in ('pending', 'published')),
  -- A hash of the sending install's ID; null for the seed tool.
  install_key text,
  -- The other song a pending print matched when it was shared.
  conflict_song_id public.slug references public.songs (id) on delete set null,
  created_at timestamptz not null default clock_timestamp()
);

create unique index track_prints_install_idx
  on public.track_prints (song_id, install_key)
  where status = 'pending';
create index track_prints_song_idx on public.track_prints (song_id);

-- The keys of published prints: every 16th value's top 20 bits.
create table public.track_print_keys (
  key integer not null,
  print_id bigint not null references public.track_prints (id) on delete cascade
);

create index track_print_keys_key_idx on public.track_print_keys (key, print_id);
create index track_print_keys_print_idx on public.track_print_keys (print_id);

alter table public.track_prints enable row level security;
alter table public.track_print_keys enable row level security;

-- Prints at most this far apart are the same recording (zema_core's
-- trackPrintMatch).
create function public.track_print_match()
returns numeric
language sql
immutable
as $$ select 0.30 $$;

-- The top 20 bits of a print value: zema_core's printKeys.
create function public.track_print_key(v integer)
returns integer
language sql
immutable
as $$ select (v >> 12) & 1048575 $$;

-- The distinct keys of every [stride]-th value of [print], skipping silence.
create function public.track_print_keys(print integer[], stride integer)
returns integer[]
language sql
immutable
set search_path = ''
as $$
  select coalesce(array_agg(distinct public.track_print_key(t.v)), '{}')
  from unnest(print) with ordinality as t(v, i)
  where t.v <> 0 and (t.i - 1) % stride = 0
$$;

-- Share of differing bits between a[i] and b[i + shift], or null when they
-- overlap by less than 650 values (30 s).
create function public.track_print_bits(a integer[], b integer[], shift integer)
returns numeric
language sql
immutable
set search_path = ''
as $$
  select sum(bit_count((a[i] # b[i + shift])::bit(32)))::numeric / (32 * count(*))
  from generate_series(greatest(1, 1 - shift), least(cardinality(a), cardinality(b) - shift)) i
  having count(*) >= 650
$$;

-- How far apart prints a and b are: the fewest differing bits at a shift of
-- at most 2 s (43 values), as zema_core's printDistance. Only the shifts the
-- prints' keys vote for (every value of a against every 4th of b) are tried,
-- each ±1, so it costs a few comparisons instead of 87.
create function public.track_print_distance(
  a integer[], b integer[], out bits numeric, out shift integer
)
language sql
immutable
set search_path = ''
as $$
  with ka as (
    select public.track_print_key(t.v) as k, t.i::integer as i
    from unnest(a) with ordinality as t(v, i) where t.v <> 0
  ),
  kb as (
    select public.track_print_key(t.v) as k, t.i::integer as i
    from unnest(b) with ordinality as t(v, i) where t.v <> 0 and (t.i - 1) % 4 = 0
  ),
  votes as (
    select v.s from (
      select kb.i - ka.i as s, count(*) as n
      from ka join kb on kb.k = ka.k
      where abs(kb.i - ka.i) <= 43
      group by 1
    ) v
    order by v.n desc, abs(v.s)
    limit 3
  ),
  tries as (
    select distinct v.s + d.d as s
    from votes v cross join (values (-1), (0), (1)) as d(d)
    where abs(v.s + d.d) <= 43
  )
  select x.bits, t.s
  from tries t
  cross join lateral (select public.track_print_bits(a, b, t.s) as bits) x
  where x.bits is not null
  order by x.bits, abs(t.s)
  limit 1
$$;

revoke all on function public.track_print_keys(integer[], integer) from public, anon, authenticated;
revoke all on function public.track_print_bits from public, anon, authenticated;
revoke all on function public.track_print_distance from public, anon, authenticated;

-- The first rule a sent print breaks, or null: 650 to 2,600 values (30 to 120
-- s) and a file of 30 s to 2 hours.
create function public.track_print_error(version integer, print integer[], duration_ms integer)
returns text
language sql
immutable
set search_path = ''
as $$
  select case
    when version is null or version not between 1 and 32767
      or print is null or cardinality(print) not between 650 and 2600
      or array_position(print, null) is not null
      or duration_ms is null or duration_ms not between 30000 and 7200000
    then 'bad_print'
  end
$$;

revoke all on function public.track_print_error from public, anon, authenticated;

-- Published prints of approved songs that match [print], best first: one row
-- per song. Candidates are the 20 prints sharing the most keys.
create function public.track_print_candidates(
  version integer, print integer[], max_results integer
)
returns table (song_id public.slug, print_id bigint, bits numeric, shift integer)
language sql
stable
set search_path = ''
as $$
  with q as (
    select distinct public.track_print_key(t.v) as k
    from unnest(print) as t(v) where t.v <> 0
  ),
  hits as (
    select pk.print_id, count(*) as n
    from q join public.track_print_keys pk on pk.key = q.k
    group by pk.print_id
    having count(*) >= 3
    order by n desc
    limit 20
  ),
  scored as (
    select p.song_id, p.id, d.bits, d.shift
    from hits h
    join public.track_prints p on p.id = h.print_id
      and p.status = 'published' and p.version = track_print_candidates.version
    join public.songs s on s.id = p.song_id and s.status = 'approved'
    cross join lateral public.track_print_distance(track_print_candidates.print, p.print) d
    where d.bits <= public.track_print_match()
  ),
  per_song as (
    select distinct on (sc.song_id) sc.song_id, sc.id, sc.bits, sc.shift
    from scored sc
    order by sc.song_id, sc.bits
  )
  select ps.song_id, ps.id, ps.bits, ps.shift
  from per_song ps
  order by ps.bits, ps.song_id
  limit greatest(1, least(max_results, 10))
$$;

revoke all on function public.track_print_candidates from public, anon, authenticated;

-- Publishes [target], giving it keys, and drops pending prints of its song
-- that match it.
create function public.publish_track_print(target bigint)
returns void
language plpgsql
set search_path = ''
as $$
declare
  published public.track_prints;
begin
  update public.track_prints p set status = 'published', install_key = null,
    conflict_song_id = null
  where p.id = target
  returning * into published;
  insert into public.track_print_keys (key, print_id)
  select k, published.id
  from unnest(public.track_print_keys(published.print, 16)) as k;
  delete from public.track_prints p
  where p.song_id = published.song_id and p.status = 'pending'
    and p.version = published.version
    and (public.track_print_distance(p.print, published.print)).bits
      <= public.track_print_match();
end
$$;

revoke all on function public.publish_track_print from public, anon, authenticated;

-- Seed tool --------------------------------------------------------------------

-- Publishes a print of [song] unless one of its prints already matches it.
-- For the seed tool (service key).
create function public.put_track_print(
  song text, version integer, print integer[], duration_ms integer
)
returns text
language plpgsql
security definer
set search_path = ''
as $$
declare
  added bigint;
begin
  if public.track_print_error(version, put_track_print.print, duration_ms) is not null then
    raise exception 'bad_print' using errcode = '22023';
  end if;
  if exists (
    select 1 from public.track_prints p
    where p.song_id = song and p.status = 'published' and p.version = put_track_print.version
      and (public.track_print_distance(put_track_print.print, p.print)).bits
        <= public.track_print_match()
  ) then
    return 'not_needed';
  end if;
  insert into public.track_prints (song_id, version, print, duration_ms)
  values (song, version, put_track_print.print, put_track_print.duration_ms)
  returning id into added;
  perform public.publish_track_print(added);
  return 'published';
end
$$;

revoke all on function public.put_track_print from public, anon, authenticated;
grant execute on function public.put_track_print to service_role;

-- Lookups ----------------------------------------------------------------------

-- The approved songs a library file's print matches, best first: [bits] is the
-- share of differing bits, [shift] how many values later the file's print
-- starts. Counts against the install (300 a day) and IP address (2,000);
-- past either, HTTP 429.
create function public.match_track(
  version integer,
  print integer[],
  duration_ms integer,
  install_id text,
  max_results integer default 3
)
returns table (song_id public.slug, bits numeric, shift integer)
language plpgsql
security definer
set search_path = ''
as $$
declare
  install_key text;
  ip text;
begin
  if install_id is null or length(install_id) not between 8 and 64 then
    raise exception 'Invalid install ID' using errcode = '22023';
  end if;
  if public.track_print_error(version, match_track.print, duration_ms) is not null then
    raise exception 'bad_print' using errcode = '22023';
  end if;
  install_key := 'print:' || encode(extensions.digest(install_id, 'sha256'), 'hex');
  ip := trim(split_part(coalesce(
    nullif(current_setting('request.headers', true), '')::json ->> 'x-forwarded-for', ''), ',', 1));
  if not public.count_identify(install_key, 300)
    or (ip <> '' and not public.count_identify(
      'print-ip:' || encode(extensions.digest(ip, 'sha256'), 'hex'), 2000)) then
    raise exception 'too_many_today' using errcode = 'PT429';
  end if;
  return query
  select c.song_id, round(c.bits, 4), c.shift
  from public.track_print_candidates(version, match_track.print, max_results) c;
  if found then
    update public.identify_counts c set matches = c.matches + 1
    where c.key = install_key and c.day = current_date;
  end if;
end
$$;

revoke all on function public.match_track from public;
grant execute on function public.match_track to anon, authenticated, service_role;

-- Sharing ----------------------------------------------------------------------

-- Shares the print of a library file linked to [song] (by title or by hand)
-- from install [install_id], at most 30 a day:
--   'not_needed'  the song isn't approved, or one of its prints matches this
--   'published'   another install sent a matching print for the song
--   'pending'     until then, or held for a moderator when it matches a
--                 different song's print
-- The file must be as long as one of the song's recordings (within 3 s or
-- 5 %) when their lengths are known.
create function public.share_track_print(
  song text,
  version integer,
  print integer[],
  duration_ms integer,
  install_id text
)
returns text
language plpgsql
security definer
set search_path = ''
as $$
declare
  sender text;
  conflict public.slug;
  mine public.track_prints;
  other public.track_prints;
begin
  if install_id is null or length(install_id) not between 8 and 64 then
    raise exception 'Invalid install ID' using errcode = '22023';
  end if;
  sender := encode(extensions.digest(install_id, 'sha256'), 'hex');
  if not public.count_identify('print-share:' || sender, 30) then
    raise exception 'too_many_today' using errcode = 'PT429';
  end if;
  if not exists (select 1 from public.songs s where s.id = song and s.status = 'approved') then
    return 'not_needed';
  end if;
  if public.track_print_error(version, share_track_print.print, share_track_print.duration_ms)
      is not null
    or (exists (
        select 1 from public.recordings r
        where r.song_id = song and r.duration_ms is not null)
      and not exists (
        select 1 from public.recordings r
        where r.song_id = song and r.duration_ms is not null
          and abs(r.duration_ms - share_track_print.duration_ms)
            <= greatest(3000, r.duration_ms * 0.05))) then
    raise exception 'bad_print' using errcode = '22023';
  end if;

  select c.song_id into conflict
  from public.track_print_candidates(version, share_track_print.print, 3) c
  order by c.song_id = song desc, c.bits
  limit 1;
  if conflict = song then
    return 'not_needed';
  end if;

  insert into public.track_prints
    (song_id, version, print, duration_ms, install_key, conflict_song_id)
  values (song, version, share_track_print.print, share_track_print.duration_ms, sender,
    conflict)
  on conflict (song_id, install_key) where status = 'pending' do update set
    version = excluded.version,
    print = excluded.print,
    duration_ms = excluded.duration_ms,
    conflict_song_id = excluded.conflict_song_id,
    created_at = clock_timestamp()
  returning * into mine;
  if conflict is not null then
    return 'pending';
  end if;

  for other in
    select * from public.track_prints p
    where p.song_id = song and p.status = 'pending' and p.install_key <> sender
      and p.version = mine.version and p.conflict_song_id is null
    order by p.created_at
  loop
    if (public.track_print_distance(mine.print, other.print)).bits
        <= public.track_print_match() then
      perform public.publish_track_print(other.id);
      return 'published';
    end if;
  end loop;
  return 'pending';
end
$$;

revoke all on function public.share_track_print from public;
grant execute on function public.share_track_print to anon, authenticated;

-- Moderators -------------------------------------------------------------------

-- Prints waiting for a moderator, oldest first: the song, how many installs
-- sent a print for it, and the other song it matched, if any.
create function public.moderator_track_prints()
returns table (
  id bigint,
  song_id text,
  song_title text,
  song_artist text,
  duration_ms integer,
  installs integer,
  conflict_song_id text,
  conflict_song_title text,
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
  select p.id, s.id::text, s.title, s.artist, p.duration_ms,
    (select count(*)::integer from public.track_prints o
      where o.song_id = p.song_id and o.status = 'pending'),
    c.id::text, c.title, p.created_at
  from public.track_prints p
  join public.songs s on s.id = p.song_id
  left join public.songs c on c.id = p.conflict_song_id
  where p.status = 'pending'
  order by p.created_at, p.id;
end
$$;

revoke all on function public.moderator_track_prints from public, anon;
grant execute on function public.moderator_track_prints to authenticated;

-- Publishes ([approve]) or drops the pending print [id].
create function public.review_track_print(id bigint, approve boolean)
returns void
language plpgsql
security definer
set search_path = ''
as $$
declare
  target public.track_prints;
begin
  perform public.require_moderator();
  select * into target
  from public.track_prints p
  where p.id = review_track_print.id and p.status = 'pending'
  for update;
  if target.id is null then
    raise exception 'unknown_print' using errcode = '22023';
  end if;
  if approve then
    perform public.publish_track_print(target.id);
  else
    delete from public.track_prints p where p.id = target.id;
  end if;
end
$$;

revoke all on function public.review_track_print from public, anon;
grant execute on function public.review_track_print to authenticated;
