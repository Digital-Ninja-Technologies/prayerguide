-- Lets a user add their own YouTube channel (e.g. their home church, if it
-- isn't in the built-in directory) to the Channel tab via the "+" button —
-- distinct from favorite_channels (0022), which marks curated/custom
-- entries as favorites rather than owning them.

create table if not exists public.custom_channels (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users (id) on delete cascade,
  channel_name text not null,
  channel_url text not null,
  created_at timestamptz not null default now()
);

alter table public.custom_channels enable row level security;

drop policy if exists "Custom channels are owner-only" on public.custom_channels;
create policy "Custom channels are owner-only" on public.custom_channels
  for all using (auth.uid() = user_id) with check (auth.uid() = user_id);
