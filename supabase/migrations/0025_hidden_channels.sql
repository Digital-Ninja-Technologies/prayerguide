-- Lets a user permanently remove a curated (or "Your church" env-config)
-- entry from the Channel tab's list — distinct from favorite_channels
-- (unliking, which they can still re-favorite) and custom_channels
-- (deleting one they own). Hiding is keyed by URL rather than an id since
-- these entries aren't rows the user owns — the curated directory lives in
-- the app's own static data, not a table.

create table if not exists public.hidden_channels (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users (id) on delete cascade,
  channel_url text not null,
  created_at timestamptz not null default now(),
  unique (user_id, channel_url)
);

alter table public.hidden_channels enable row level security;

drop policy if exists "Hidden channels are owner-only" on public.hidden_channels;
create policy "Hidden channels are owner-only" on public.hidden_channels
  for all using (auth.uid() = user_id) with check (auth.uid() = user_id);
