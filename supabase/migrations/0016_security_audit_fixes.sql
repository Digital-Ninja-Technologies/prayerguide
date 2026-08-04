-- Security audit fixes.
--
-- All four issues below share the same root cause: an RLS policy allowed a
-- direct client write that was supposed to only ever happen through a
-- SECURITY DEFINER function (or, for subscriptions, a trusted server). None
-- of these functions/paths needed the broader grant to keep working —
-- SECURITY DEFINER functions run as their owner and bypass RLS entirely.

-- ---------------------------------------------------------------------------
-- 1. Companions: pairing must go through redeem_companion_invite().
-- ---------------------------------------------------------------------------
-- "insert with check (auth.uid() in (user_a, user_b))" only required naming
-- yourself as one side of the pair — nothing required an actual invite to
-- have been redeemed. Any authenticated user could POST a companions row
-- naming any other user_id directly: no consent from the other side, and it
-- skipped the free-tier one-companion limit that's only enforced inside
-- redeem_companion_invite() (0011). That function is SECURITY DEFINER, so
-- dropping this policy blocks direct inserts without touching the redeem
-- flow itself.
drop policy if exists "Companions insertable by either member" on public.companions;

-- ---------------------------------------------------------------------------
-- 2. Subscriptions: tier becomes server-controlled only.
-- ---------------------------------------------------------------------------
-- tier was owner-writable, and it's the exact column redeem_companion_invite()
-- (and the client's own no-RevenueCat fallback in SubscriptionRepository)
-- trust as ground truth for Premium — so a forged row unlocked every
-- premium-gated feature for free. From here on, only the revenuecat-webhook
-- Edge Function (using the service-role key, which bypasses RLS) may write
-- this table; owners can still read their own row.
drop policy if exists "Subscriptions are owner-only" on public.subscriptions;
create policy "Subscriptions are viewable by owner" on public.subscriptions
  for select using (auth.uid() = user_id);

-- ---------------------------------------------------------------------------
-- 3. Companion invites: no reason for a public lookup policy.
-- ---------------------------------------------------------------------------
-- The app never selects from this table directly — only .insert() to create
-- an invite, and the redeem_companion_invite() RPC (itself SECURITY
-- DEFINER, so it doesn't rely on this grant either) to redeem one. Letting
-- any authenticated user read every pending code/inviter let anyone race
-- the intended recipient and redeem someone else's invite first.
drop policy if exists "Anyone authenticated can look up an invite by code" on public.companion_invites;

-- ---------------------------------------------------------------------------
-- 4. Group members: joining requires the group's invite code.
-- ---------------------------------------------------------------------------
-- The old policy let any authenticated user insert themselves into *any*
-- group_id with no check that they'd presented that group's invite code —
-- redeem_group_invite() (0008) was enforced only by app convention, not the
-- database. The one legitimate direct insert is a group's creator adding
-- themselves as its first member right after creating it
-- (GroupsRepository.createGroup); joining someone else's group must go
-- through redeem_group_invite(), which is SECURITY DEFINER and bypasses
-- this policy entirely.
drop policy if exists "Users can join/leave for themselves" on public.group_members;

create policy "Members can leave for themselves" on public.group_members
  for delete using (auth.uid() = user_id);

create policy "Creator can add themselves as first member" on public.group_members
  for insert with check (
    auth.uid() = user_id
    and exists (select 1 from public.groups g where g.id = group_id and g.created_by = auth.uid())
  );
