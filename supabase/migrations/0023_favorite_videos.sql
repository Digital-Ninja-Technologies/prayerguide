-- Favoriting an individual video (not just a whole channel) from inside
-- ChannelWebviewScreen. Distinct from favorite_channels (migration 0022) —
-- a user can favorite a channel, a specific video on it, or both.

create table if not exists public.favorite_videos (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users (id) on delete cascade,
  video_title text not null,
  video_url text not null,
  created_at timestamptz not null default now(),
  unique (user_id, video_url)
);

alter table public.favorite_videos enable row level security;

drop policy if exists "Favorite videos are owner-only" on public.favorite_videos;
create policy "Favorite videos are owner-only" on public.favorite_videos
  for all using (auth.uid() = user_id) with check (auth.uid() = user_id);
