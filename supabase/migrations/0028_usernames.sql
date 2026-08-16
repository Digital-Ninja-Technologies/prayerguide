-- Every account gets a unique, public @username handle — the primary way
-- people find/share with each other going forward, replacing the
-- exact-email-only path search_users previously offered. The real identity
-- stays the auth.users/profiles UUID everywhere else (FKs, storage paths,
-- RLS); this is purely a public lookup handle layered on top.
--
-- Nullable on purpose: existing accounts have no username until the app's
-- forced one-time gate (ChooseUsernameScreen) sets one — there's no backfill
-- here, this migration only adds the plumbing.
alter table public.profiles
  add column if not exists username text;

alter table public.profiles
  drop constraint if exists profiles_username_format;
alter table public.profiles
  add constraint profiles_username_format
    check (username is null or username ~ '^[a-z0-9_]{3,20}$');

-- Partial unique index: any number of NULLs allowed, unique only once set.
create unique index if not exists profiles_username_unique_idx
  on public.profiles (username)
  where username is not null;

-- Read-only availability check — needs to work for a user who doesn't have
-- a session yet (the onboarding create-account form checks this before
-- signUp() exists), unlike every other RPC in this app which is
-- authenticated-only.
create or replace function public.is_username_available(check_username text)
returns boolean
language sql
security definer set search_path = public
as $$
  select not exists (
    select 1 from public.profiles where username = lower(check_username)
  );
$$;

grant execute on function public.is_username_available(text) to anon, authenticated;

-- handle_new_user(): add username to the row created at signup, sourced
-- from signUp()'s `data: {'username': ...}` metadata (0003_name_from_oauth_metadata.sql
-- established this same pattern for `name`). NULL for OAuth/no-username
-- signups — they just hit the forced gate like any pre-existing account.
create or replace function public.handle_new_user()
returns trigger
language plpgsql
security definer set search_path = public
as $$
begin
  insert into public.profiles (id, name, email, username)
  values (
    new.id,
    coalesce(
      nullif(new.raw_user_meta_data ->> 'name', ''),
      nullif(new.raw_user_meta_data ->> 'full_name', ''),
      nullif(trim(concat_ws(' ',
        new.raw_user_meta_data ->> 'given_name',
        new.raw_user_meta_data ->> 'family_name'
      )), ''),
      ''
    ),
    new.email,
    nullif(new.raw_user_meta_data ->> 'username', '')
  )
  on conflict (id) do nothing;
  return new;
end;
$$;

-- search_users(): add a username field to the results, and a leading '@'
-- search mode. CREATE OR REPLACE can't change a RETURNS TABLE column list,
-- so the old signature has to be dropped first.
drop function if exists public.search_users(text);

create function public.search_users(query text)
returns table (id uuid, name text, username text)
language sql
security definer set search_path = public
as $$
  select p.id, p.name, p.username
  from public.profiles p
  where p.id <> auth.uid()
    and (
      case
        when left(query, 1) = '@' then p.username ilike substring(query from 2) || '%'
        when query ilike '%@%' then lower(p.email) = lower(query)
        else p.name ilike query || '%'
      end
    )
  limit 20;
$$;

grant execute on function public.search_users(text) to authenticated;
