-- The free-plan "one companion" limit was only enforced client-side (see
-- pushInviteCompanion() / requirePremium() in the Flutter app), which only
-- gates the person who taps Invite or pastes a code — not the *other* side
-- of that pairing. A free user could still end up with a second companion
-- if someone else redeemed their invite (or they redeemed someone else's),
-- since redeem_companion_invite() itself never checked anyone's plan.
-- This closes that gap at the one place a pairing actually gets created.
create or replace function public.redeem_companion_invite(invite_code text)
returns uuid
language plpgsql
security definer set search_path = public
as $$
declare
  inv record;
  pair_id uuid;
  inviter_tier text;
  inviter_count int;
  redeemer_tier text;
  redeemer_count int;
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
    -- Free plan includes one companion; Premium unlocks unlimited. Check
    -- both sides of the pairing, since either could already be at the
    -- limit regardless of who's the one calling redeem right now.
    select tier into inviter_tier from public.subscriptions where user_id = inv.inviter_id;
    select count(*) into inviter_count from public.companions
      where inv.inviter_id in (user_a, user_b);
    if coalesce(inviter_tier, 'free') <> 'premium' and inviter_count >= 1 then
      raise exception 'This person already has a companion on the free plan.';
    end if;

    select tier into redeemer_tier from public.subscriptions where user_id = auth.uid();
    select count(*) into redeemer_count from public.companions
      where auth.uid() in (user_a, user_b);
    if coalesce(redeemer_tier, 'free') <> 'premium' and redeemer_count >= 1 then
      raise exception 'You already have a companion on the free plan. Upgrade to Premium to add more.';
    end if;

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
