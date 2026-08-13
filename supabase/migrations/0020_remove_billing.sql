-- Payment/Premium is removed — the app is entirely free now. This drops the
-- free-tier "one companion" cap (redeem_companion_invite no longer checks
-- anyone's plan, so pairing just always succeeds), and removes the billing
-- data model that backed it: the `subscriptions` table (previously synced
-- server-side by the revenuecat-webhook Edge Function per migration
-- `0016_security_audit_fixes.sql`, now deleted along with RevenueCat
-- itself) and `profiles.premium` (was never actually read anywhere — the
-- app's real premium flag always lived in `subscriptions`). The other three
-- fixes from 0016 (companions/invites/group_members RLS) are unrelated to
-- billing and stay as they are.

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

drop table if exists public.subscriptions;

alter table public.profiles drop column if exists premium;
