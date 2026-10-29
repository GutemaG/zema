-- Catalog search (intent 004, bolt 020, story 005).
--
-- Every song has a title entry (title, transliteration, artist) and one entry
-- per line (text, transliteration), each holding its search words and
-- skeletons from the generated rules (…_search_rules.sql). search_songs scores
-- the query against the distinct vocabulary first, so edit distances are
-- worked out once per word rather than once per line, then ranks entries the
-- way zema_core's matchScore does.

create table public.search_entries (
  id bigint generated always as identity primary key,
  song_id public.slug not null references public.songs (id) on delete cascade,
  -- Null for the title entry.
  section_id text,
  line_position integer,
  words text[] not null,
  skeletons text[] not null,
  foreign key (song_id, section_id, line_position)
    references public.lines (song_id, section_id, position) on delete cascade
);

create unique index search_entries_place_idx
  on public.search_entries (song_id, coalesce(section_id, ''), coalesce(line_position, -1));

create table public.search_vocab (
  word text primary key,
  skeleton text not null
);

create table public.search_entry_words (
  entry_id bigint not null references public.search_entries (id) on delete cascade,
  word text not null references public.search_vocab (word),
  primary key (word, entry_id)
);

-- Not readable or writable through the API; search_songs reads them.
alter table public.search_entries enable row level security;
alter table public.search_vocab enable row level security;
alter table public.search_entry_words enable row level security;

-- Stores the entry for one place in a song.
create function public.index_search_entry(
  target_song public.slug,
  target_section text,
  target_position integer,
  content text
)
returns void
language plpgsql
set search_path = ''
as $$
declare
  entry_words text[] := public.zema_search_words(content);
  entry_skeletons text[] := public.zema_skeletons(entry_words);
  entry bigint;
begin
  delete from public.search_entries e
  where e.song_id = target_song
    and e.section_id is not distinct from target_section
    and e.line_position is not distinct from target_position;
  if cardinality(entry_words) = 0 then
    return;
  end if;
  insert into public.search_entries (song_id, section_id, line_position, words, skeletons)
  values (target_song, target_section, target_position, entry_words, entry_skeletons)
  returning id into entry;
  insert into public.search_vocab (word, skeleton)
  select w, s from unnest(entry_words, entry_skeletons) as t(w, s)
  on conflict (word) do nothing;
  insert into public.search_entry_words (entry_id, word)
  select distinct entry, w from unnest(entry_words) as w;
end
$$;

create function public.songs_index_search()
returns trigger
language plpgsql
set search_path = ''
as $$
begin
  if tg_op = 'INSERT' or (new.title, new.transliteration, new.artist)
      is distinct from (old.title, old.transliteration, old.artist) then
    perform public.index_search_entry(
      new.id, null, null,
      concat_ws(' ', new.title, new.transliteration, new.artist)
    );
  end if;
  return null;
end
$$;

create trigger songs_index_search after insert or update on public.songs
  for each row execute function public.songs_index_search();

create function public.lines_index_search()
returns trigger
language plpgsql
set search_path = ''
as $$
begin
  perform public.index_search_entry(
    new.song_id, new.section_id, new.position,
    concat_ws(' ', new.text, new.transliteration)
  );
  return null;
end
$$;

create trigger lines_index_search after insert or update on public.lines
  for each row execute function public.lines_index_search();

-- Approved songs matching [query], each once, best first (then by ID).
-- line_text is the best-matching line when it scores higher than the title.
create function public.search_songs(query text, max_results integer default 20)
returns table (
  song_id text,
  title text,
  transliteration text,
  artist text,
  score double precision,
  line_text text,
  line_transliteration text
)
language plpgsql
stable
security definer
set search_path = ''
as $$
declare
  query_words text[] := public.zema_search_words(query);
  query_skeletons text[] := public.zema_skeletons(query_words);
  n integer := cardinality(query_words);
begin
  if n = 0 then
    return;
  end if;
  return query
  with word_scores as materialized (
    -- Each query word against each distinct word in the catalog, scored once.
    -- An entry reaches the threshold t only if every query word scores at
    -- least t·n − (n − 1) in it (the others can add at most 1 each), so
    -- weaker word matches can never contribute to a result: drop them before
    -- following any links. This changes no result, only the work.
    select q.i, v.word,
      public.zema_word_score(query_words[q.i], query_skeletons[q.i], v.word, v.skeleton) as s
    from generate_subscripts(query_words, 1) as q(i)
    cross join public.search_vocab v
  ),
  useful as materialized (
    select ws.i, ws.word, ws.s
    from word_scores ws
    where ws.s > 0
      and ws.s >= public.zema_match_threshold() * n - (n - 1)
  ),
  entry_best as (
    select ew.entry_id, u.i, max(u.s) as best
    from useful u
    join public.search_entry_words ew on ew.word = u.word
    group by ew.entry_id, u.i
  ),
  entry_scores as materialized (
    -- Computed once, before joining songs (a plain CTE can be re-evaluated per
    -- song when the planner misjudges its size).
    select eb.entry_id, sum(eb.best order by eb.i) / n as s
    from entry_best eb
    group by eb.entry_id
    having sum(eb.best order by eb.i) / n >= public.zema_match_threshold()
  ),
  ranked as (
    select e.song_id, e.section_id, e.line_position, es.s,
      so.title, so.transliteration, so.artist,
      row_number() over (
        partition by e.song_id
        -- The title wins ties; then the earliest line, as zema_core keeps the
        -- first best line.
        order by es.s desc, (e.section_id is not null), sec.position, e.line_position
      ) as place
    from entry_scores es
    join public.search_entries e on e.id = es.entry_id
    join public.songs so on so.id = e.song_id and so.status = 'approved'
    left join public.sections sec on sec.song_id = e.song_id and sec.id = e.section_id
  ),
  top as materialized (
    -- Pick the results before fetching their lines.
    select r.*
    from ranked r
    where r.place = 1
    order by r.s desc, r.song_id collate "C"
    limit greatest(max_results, 0)
  )
  select t.song_id::text, t.title, t.transliteration, t.artist, t.s,
    l.text, l.transliteration
  from top t
  left join public.lines l
    on l.song_id = t.song_id and l.section_id = t.section_id and l.position = t.line_position
  order by t.s desc, t.song_id collate "C";
end
$$;

revoke all on function public.search_songs from public;
grant execute on function public.search_songs to anon, authenticated;
