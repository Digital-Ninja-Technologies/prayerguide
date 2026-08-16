-- Lets a user share a sermon note with any other user on the platform (not
-- just a paired companion). On accept, the recipient gets a fully
-- independent copy — audio + notes duplicated into their own sermon_notes/
-- sermon_note_recordings rows — so every existing sermon feature (playback,
-- edit, delete, re-share) already works on it with no special-casing.
-- Follows the same pending/accepted/declined + RLS + security-definer-RPC +
-- Realtime shape as companion_prayer_invites (0021_companion_prayer_invites.sql).

-- No existing user directory/search exists anywhere in this app — companion
-- pairing is invite-code/QR only. This is the first, deliberately narrow:
-- exact-email match (never leaks a raw email back to the searcher) or
-- name-prefix match, capped at 20 rows, never including the caller.
create or replace function public.search_users(query text)
returns table (id uuid, name text)
language sql
security definer set search_path = public
as $$
  select p.id, p.name
  from public.profiles p
  where p.id <> auth.uid()
    and (
      case
        when query ilike '%@%' then lower(p.email) = lower(query)
        else p.name ilike query || '%'
      end
    )
  limit 20;
$$;

grant execute on function public.search_users(text) to authenticated;

create table if not exists public.sermon_shares (
  id uuid primary key default gen_random_uuid(),
  sermon_note_id uuid not null references public.sermon_notes (id) on delete cascade,
  sender_id uuid not null references auth.users (id) on delete cascade,
  recipient_id uuid not null references auth.users (id) on delete cascade,
  status text not null default 'pending' check (status in ('pending', 'accepted', 'declined')),
  created_at timestamptz not null default now(),
  responded_at timestamptz,
  check (sender_id <> recipient_id)
);

create unique index if not exists sermon_shares_one_pending_idx
  on public.sermon_shares (sermon_note_id, recipient_id)
  where status = 'pending';

alter table public.sermon_shares enable row level security;

drop policy if exists "Senders can view their sent shares" on public.sermon_shares;
create policy "Senders can view their sent shares" on public.sermon_shares
  for select using (auth.uid() = sender_id);

drop policy if exists "Recipients can view shares addressed to them" on public.sermon_shares;
create policy "Recipients can view shares addressed to them" on public.sermon_shares
  for select using (auth.uid() = recipient_id);

drop policy if exists "Senders can share sermons they own" on public.sermon_shares;
create policy "Senders can share sermons they own" on public.sermon_shares
  for insert with check (
    auth.uid() = sender_id
    and exists (
      select 1 from public.sermon_notes sn
      where sn.id = sermon_note_id and sn.user_id = auth.uid()
    )
  );

-- No client-facing UPDATE policy: declining goes through
-- decline_sermon_share() below; accepting goes through the
-- accept-sermon-share Edge Function, since copying the recording audio
-- between two different users' storage folders needs the Storage API
-- (service-role), not something a plain RPC can do.

alter table public.sermon_notes
  add column if not exists shared_from_user_id uuid references auth.users (id),
  add column if not exists shared_from_name text;

create or replace function public.decline_sermon_share(share_id uuid)
returns void
language plpgsql
security definer set search_path = public
as $$
declare
  sh record;
begin
  select * into sh from public.sermon_shares where id = share_id for update;
  if sh is null then
    raise exception 'That share was not found.';
  end if;
  if sh.recipient_id <> auth.uid() then
    raise exception 'You are not the recipient of this share.';
  end if;
  if sh.status != 'pending' then
    raise exception 'That share has already been responded to.';
  end if;

  update public.sermon_shares
    set status = 'declined', responded_at = now()
    where id = share_id;
end;
$$;

grant execute on function public.decline_sermon_share(uuid) to authenticated;

alter publication supabase_realtime add table public.sermon_shares;
