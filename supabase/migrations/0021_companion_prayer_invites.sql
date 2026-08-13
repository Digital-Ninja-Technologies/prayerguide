-- "Pray with Companion" live prayer invites + push notification device
-- tokens. Tapping "Pray live" (companion_detail_screen.dart) already drops
-- the requester into a real-time presence session (together_screen.dart),
-- but the other side only finds out if they happen to already be in the
-- app. This lets the requester push-notify them instead, with an
-- accept/decline the requester can see the outcome of.

-- ---------------------------------------------------------------------------
-- Device push tokens (Firebase Cloud Messaging)
-- ---------------------------------------------------------------------------
-- One row per token per user (a user can have more than one device).
-- Owner-only RLS — looking up *someone else's* token to send them a push
-- happens in the send-companion-invite-push Edge Function via the
-- service-role client, which bypasses RLS entirely, not via a broader
-- client-facing policy.
create table if not exists public.device_push_tokens (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users (id) on delete cascade,
  token text not null unique,
  platform text not null check (platform in ('ios', 'android')),
  updated_at timestamptz not null default now()
);

alter table public.device_push_tokens enable row level security;
drop policy if exists "Device push tokens are owner-only" on public.device_push_tokens;
create policy "Device push tokens are owner-only" on public.device_push_tokens
  for all using (auth.uid() = user_id) with check (auth.uid() = user_id);

-- ---------------------------------------------------------------------------
-- Prayer invites
-- ---------------------------------------------------------------------------
create table if not exists public.companion_prayer_invites (
  id uuid primary key default gen_random_uuid(),
  companion_id uuid not null references public.companions (id) on delete cascade,
  requester_id uuid not null references auth.users (id) on delete cascade,
  status text not null default 'pending' check (status in ('pending', 'accepted', 'declined')),
  created_at timestamptz not null default now(),
  responded_at timestamptz
);

-- At most one pending invite per pair at a time — a second "Pray live" tap
-- while one's already outstanding should re-use it, not spam a fresh push.
create unique index if not exists companion_prayer_invites_one_pending_idx
  on public.companion_prayer_invites (companion_id)
  where status = 'pending';

alter table public.companion_prayer_invites enable row level security;

drop policy if exists "Prayer invites visible to the companion pair" on public.companion_prayer_invites;
create policy "Prayer invites visible to the companion pair" on public.companion_prayer_invites
  for select using (
    exists (
      select 1 from public.companions c
      where c.id = companion_id and auth.uid() in (c.user_a, c.user_b)
    )
  );

drop policy if exists "Prayer invites insertable by the requester" on public.companion_prayer_invites;
create policy "Prayer invites insertable by the requester" on public.companion_prayer_invites
  for insert with check (
    auth.uid() = requester_id
    and exists (
      select 1 from public.companions c
      where c.id = companion_id and auth.uid() in (c.user_a, c.user_b)
    )
  );

-- No client-facing UPDATE policy: responding goes only through
-- respond_to_prayer_invite() below, so a client can't rewrite an invite's
-- companion_id/requester_id while "responding" to it.
create or replace function public.respond_to_prayer_invite(invite_id uuid, new_status text)
returns void
language plpgsql
security definer set search_path = public
as $$
declare
  inv record;
begin
  if new_status not in ('accepted', 'declined') then
    raise exception 'Invalid status.';
  end if;

  select * into inv from public.companion_prayer_invites where id = invite_id for update;
  if inv is null then
    raise exception 'That invite was not found.';
  end if;
  if inv.requester_id = auth.uid() then
    raise exception 'You cannot respond to your own invite.';
  end if;
  if not exists (
    select 1 from public.companions c
    where c.id = inv.companion_id and auth.uid() in (c.user_a, c.user_b)
  ) then
    raise exception 'You are not part of this companion pair.';
  end if;
  if inv.status != 'pending' then
    raise exception 'That invite has already been responded to.';
  end if;

  update public.companion_prayer_invites
    set status = new_status, responded_at = now()
    where id = invite_id;
end;
$$;

grant execute on function public.respond_to_prayer_invite(uuid, text) to authenticated;

-- The requester watches their invite's status via a postgres_changes
-- subscription (see lib/state/prayer_invite_provider.dart) to learn about a
-- decline — an accept is instead discovered the same way Prayer Together
-- always has, via Realtime Presence once the companion actually joins.
alter publication supabase_realtime add table public.companion_prayer_invites;
