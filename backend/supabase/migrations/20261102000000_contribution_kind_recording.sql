-- A recording added to an existing song (intent 006, bolt 039, story 001).
--
-- On its own because Postgres can't use an enum value in the transaction that
-- adds it.

alter type public.contribution_kind add value 'recording';
