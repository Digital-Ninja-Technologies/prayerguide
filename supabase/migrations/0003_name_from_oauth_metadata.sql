-- Google (and other OAuth) sign-ins populate user_metadata with `full_name`
-- and/or `given_name`/`family_name`, not the `name` key that email/password
-- signup writes (see AuthRepository.signUpWithEmail). handle_new_user only
-- checked `name`, so OAuth accounts got an empty profile name and fell back
-- to the "friend" placeholder on the home screen.
create or replace function public.handle_new_user()
returns trigger
language plpgsql
security definer set search_path = public
as $$
begin
  insert into public.profiles (id, name, email)
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
    new.email
  )
  on conflict (id) do nothing;
  return new;
end;
$$;

-- Backfill accounts that were already created with a blank name.
update public.profiles p
set name = coalesce(
  nullif(u.raw_user_meta_data ->> 'name', ''),
  nullif(u.raw_user_meta_data ->> 'full_name', ''),
  nullif(trim(concat_ws(' ',
    u.raw_user_meta_data ->> 'given_name',
    u.raw_user_meta_data ->> 'family_name'
  )), '')
)
from auth.users u
where u.id = p.id and p.name = '';
