-- Lets a user favorite a church channel on the Channel tab (from the
-- built-in directory, or their own CHURCH_YOUTUBE_CHANNEL_URL entry) and
-- see a "Favorites" list — owner-only, like everything else user-specific
-- in this app.

create table if not exists public.favorite_channels (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users (id) on delete cascade,
  channel_name text not null,
  channel_url text not null,
  created_at timestamptz not null default now(),
  unique (user_id, channel_url)
);

alter table public.favorite_channels enable row level security;

drop policy if exists "Favorite channels are owner-only" on public.favorite_channels;
create policy "Favorite channels are owner-only" on public.favorite_channels
  for all using (auth.uid() = user_id) with check (auth.uid() = user_id);
