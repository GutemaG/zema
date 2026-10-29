-- Delete account (intent 005, bolt 030, story 004).
--
-- Removes the caller's auth user. The cascades remove their profile, roles, backup,
-- sessions, refresh tokens and identities, so they are signed out everywhere.
-- Contributions stay with no author; reports are anonymous and stay.

create function public.delete_account()
returns void
language plpgsql
security definer
set search_path = ''
as $$
begin
  if auth.uid() is null then
    raise exception 'Not signed in' using errcode = '28000';
  end if;

  -- A second call finds no user and does nothing.
  delete from auth.users where id = auth.uid();
end;
$$;

revoke all on function public.delete_account from public, anon;
grant execute on function public.delete_account to authenticated;
