-- Lets a paired companion see just enough of your profile (name, streak) to
-- render the Companion screen — gated strictly to users who actually share
-- a row in `companions` (i.e. one of you redeemed the other's invite).
drop policy if exists "Companion's profile is visible to the other companion" on public.profiles;
create policy "Companion's profile is visible to the other companion" on public.profiles
  for select using (
    exists (
      select 1 from public.companions c
      where (c.user_a = auth.uid() and c.user_b = profiles.id)
         or (c.user_b = auth.uid() and c.user_a = profiles.id)
    )
  );

-- Redeeming an invite has to happen atomically (validate the code, then
-- create the pairing, then mark it used) and needs to insert a companions
-- row naming the *inviter* as one side — something the redeemer's own RLS
-- grant can't do directly. security definer lets this function do that
-- safely, after checking everything itself rather than trusting the client.
create or replace function public.redeem_companion_invite(invite_code text)
returns uuid
language plpgsql
security definer set search_path = public
as $$
declare
  inv record;
  pair_id uuid;
begin
  select * into inv from public.companion_invites where code = invite_code for update;

  if inv is null then
    raise exception 'That invite code was not found.';
  end if;
  if inv.redeemed_by is not null then
    raise exception 'That invite has already been used.';
  end if;
  if inv.expires_at < now() then
    raise exception 'That invite has expired.';
  end if;
  if inv.inviter_id = auth.uid() then
    raise exception 'You cannot redeem your own invite.';
  end if;

  select id into pair_id from public.companions
    where (user_a = inv.inviter_id and user_b = auth.uid())
       or (user_a = auth.uid() and user_b = inv.inviter_id);

  if pair_id is null then
    insert into public.companions (user_a, user_b)
      values (inv.inviter_id, auth.uid())
      returning id into pair_id;
  end if;

  update public.companion_invites
    set redeemed_by = auth.uid(), redeemed_at = now()
    where id = inv.id;

  return pair_id;
end;
$$;

grant execute on function public.redeem_companion_invite(text) to authenticated;
