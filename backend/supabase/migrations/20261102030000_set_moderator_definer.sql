-- set_moderator runs as its owner (intent 006, bolt 042).
--
-- It looks the user up in auth.users, which service_role can't read, so with
-- the caller's rights it only worked for the database owner. It stays
-- executable by service_role alone.

alter function public.set_moderator(text, boolean)
  security definer;
