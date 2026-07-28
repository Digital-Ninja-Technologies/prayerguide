-- Tracks real Focus Mode sessions (start/end time, mode chosen). This does
-- NOT implement actual app-blocking — that needs iOS Screen Time
-- entitlements / an Android Accessibility Service, both out of scope for
-- this codebase (see SETUP.md). This table only lets the app honestly show
-- "how long was I focused" instead of a hardcoded clock.
create table if not exists public.focus_sessions (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users (id) on delete cascade,
  mode text not null default 'gentle' check (mode in ('gentle', 'full')),
  started_at timestamptz not null default now(),
  ended_at timestamptz
);

alter table public.focus_sessions enable row level security;
drop policy if exists "Focus sessions are owner-only" on public.focus_sessions;
create policy "Focus sessions are owner-only" on public.focus_sessions
  for all using (auth.uid() = user_id) with check (auth.uid() = user_id);
