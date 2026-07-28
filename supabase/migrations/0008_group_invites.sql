-- Groups already have member-only RLS (see 0001_init.sql), which means a
-- non-member can't SELECT a group row to discover its id — so joining needs
-- a short shareable code plus a security-definer lookup, the same pattern
-- used for companion invites.
alter table public.groups add column if not exists invite_code text;
create unique index if not exists groups_invite_code_idx on public.groups (invite_code) where invite_code is not null;

create or replace function public.redeem_group_invite(p_code text)
returns uuid
language plpgsql
security definer set search_path = public
as $$
declare
  grp record;
begin
  select * into grp from public.groups where invite_code = p_code;

  if grp is null then
    raise exception 'That group code was not found.';
  end if;

  insert into public.group_members (group_id, user_id)
    values (grp.id, auth.uid())
    on conflict (group_id, user_id) do nothing;

  return grp.id;
end;
$$;

grant execute on function public.redeem_group_invite(text) to authenticated;
