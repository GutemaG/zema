-- Hidden songs (intent 008, bolt 054, story 002).
--
-- A moderator hides a bad song instead of deleting it. Everything listeners read
-- (song_index, get_song, search, reports, contributions, fingerprints) already
-- keeps to approved songs, so a hidden one drops out everywhere. A value added
-- to an enum can't be used in the transaction that adds it, hence its own file.

alter type public.song_status add value 'hidden';
