-- Prayer Guide — initial schema
-- Run via `supabase db push` (with the project linked) or paste into the
-- Supabase SQL editor. Requires the service role / project owner — the
-- app's anon key cannot run DDL.

create extension if not exists "pgcrypto";

-- ---------------------------------------------------------------------------
-- Profiles
-- ---------------------------------------------------------------------------
create table if not exists public.profiles (
  id uuid primary key references auth.users (id) on delete cascade,
  name text not null default '',
  email text,
  streak_count integer not null default 0,
  longest_streak integer not null default 0,
  last_prayed_on date,
  streak_freezes_available integer not null default 1,
  hide_streak_count boolean not null default false,
  theme_preference text not null default 'dark' check (theme_preference in ('dark', 'light')),
  premium boolean not null default false,
  created_at timestamptz not null default now()
);

alter table public.profiles enable row level security;

create policy "Profiles are viewable by owner" on public.profiles
  for select using (auth.uid() = id);
create policy "Profiles are editable by owner" on public.profiles
  for update using (auth.uid() = id);
create policy "Profiles are insertable by owner" on public.profiles
  for insert with check (auth.uid() = id);

-- Auto-create a profile row whenever a new auth user is created.
create or replace function public.handle_new_user()
returns trigger
language plpgsql
security definer set search_path = public
as $$
begin
  insert into public.profiles (id, name, email)
  values (new.id, coalesce(new.raw_user_meta_data ->> 'name', ''), new.email)
  on conflict (id) do nothing;
  return new;
end;
$$;

drop trigger if exists on_auth_user_created on auth.users;
create trigger on_auth_user_created
  after insert on auth.users
  for each row execute procedure public.handle_new_user();

-- ---------------------------------------------------------------------------
-- Journal entries
-- ---------------------------------------------------------------------------
-- title_cipher/body_cipher hold client-side AES-256-GCM ciphertext (base64),
-- encrypted/decrypted on-device only — see lib/core/security/encryption_service.dart.
-- The server never sees, and cannot recover, the plaintext.
create table if not exists public.journal_entries (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users (id) on delete cascade,
  type text not null check (type in ('Gratitude', 'Request', 'Testimony', 'Reflection')),
  title_cipher text not null,
  body_cipher text not null default '',
  created_at timestamptz not null default now()
);

alter table public.journal_entries enable row level security;
create policy "Journal entries are owner-only" on public.journal_entries
  for all using (auth.uid() = user_id) with check (auth.uid() = user_id);

-- ---------------------------------------------------------------------------
-- Prayer requests
-- ---------------------------------------------------------------------------
-- title_cipher/note_cipher are client-side-encrypted (see journal_entries
-- above). category/status/reminder stay plaintext — they're needed for
-- server-side filtering and don't expose the sensitive free-text content.
create table if not exists public.prayer_requests (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users (id) on delete cascade,
  category text not null default 'Other',
  title_cipher text not null,
  note_cipher text,
  status text not null default 'active' check (status in ('active', 'answered', 'archived')),
  reminder boolean not null default false,
  shared_with_companion boolean not null default false,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

alter table public.prayer_requests enable row level security;
create policy "Prayer requests are owner-only" on public.prayer_requests
  for all using (auth.uid() = user_id) with check (auth.uid() = user_id);

-- ---------------------------------------------------------------------------
-- Prayer sessions (feeds the streak)
-- ---------------------------------------------------------------------------
create table if not exists public.prayer_sessions (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users (id) on delete cascade,
  category text,
  duration_seconds integer not null,
  completed_at timestamptz not null default now()
);

alter table public.prayer_sessions enable row level security;
create policy "Prayer sessions are owner-only" on public.prayer_sessions
  for all using (auth.uid() = user_id) with check (auth.uid() = user_id);

-- Minimum session length (seconds) that counts toward the streak, per PRD §8.
create or replace function public.qualifying_session_seconds()
returns integer language sql immutable as $$ select 180 $$;

-- Recompute streak_count/last_prayed_on/longest_streak after a qualifying
-- session. Consecutive-day logic with a 1-day grace via streak_freezes_available.
create or replace function public.handle_prayer_session()
returns trigger
language plpgsql
security definer set search_path = public
as $$
declare
  today date := (new.completed_at at time zone 'utc')::date;
  prev date;
  cur_count integer;
  cur_longest integer;
begin
  if new.duration_seconds < public.qualifying_session_seconds() then
    return new;
  end if;

  select last_prayed_on, streak_count, longest_streak
    into prev, cur_count, cur_longest
    from public.profiles where id = new.user_id;

  if prev is null then
    cur_count := 1;
  elsif prev = today then
    -- already counted today
    return new;
  elsif prev = today - 1 then
    cur_count := cur_count + 1;
  else
    cur_count := 1; -- streak broken, restart
  end if;

  update public.profiles
    set streak_count = cur_count,
        longest_streak = greatest(coalesce(cur_longest, 0), cur_count),
        last_prayed_on = today
    where id = new.user_id;

  return new;
end;
$$;

drop trigger if exists on_prayer_session_insert on public.prayer_sessions;
create trigger on_prayer_session_insert
  after insert on public.prayer_sessions
  for each row execute procedure public.handle_prayer_session();

-- ---------------------------------------------------------------------------
-- Bible bookmarks / highlights / notes
-- ---------------------------------------------------------------------------
create table if not exists public.bible_notes (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users (id) on delete cascade,
  kind text not null check (kind in ('highlight', 'bookmark', 'note')),
  reference text not null,
  verse_text text,
  note text,
  created_at timestamptz not null default now()
);

alter table public.bible_notes enable row level security;
create policy "Bible notes are owner-only" on public.bible_notes
  for all using (auth.uid() = user_id) with check (auth.uid() = user_id);

-- ---------------------------------------------------------------------------
-- Notification preferences
-- ---------------------------------------------------------------------------
create table if not exists public.notification_prefs (
  user_id uuid primary key references auth.users (id) on delete cascade,
  morning_prayer boolean not null default true,
  morning_prayer_time time not null default '06:30',
  evening_prayer boolean not null default true,
  evening_prayer_time time not null default '20:00',
  scripture_of_day boolean not null default true,
  streak_protection boolean not null default false,
  companion_checkins boolean not null default true,
  quiet_hours_start time not null default '22:00',
  quiet_hours_end time not null default '06:00'
);

alter table public.notification_prefs enable row level security;
create policy "Notification prefs are owner-only" on public.notification_prefs
  for all using (auth.uid() = user_id) with check (auth.uid() = user_id);

-- ---------------------------------------------------------------------------
-- Companions (Phase 2)
-- ---------------------------------------------------------------------------
create table if not exists public.companion_invites (
  id uuid primary key default gen_random_uuid(),
  inviter_id uuid not null references auth.users (id) on delete cascade,
  code text not null unique,
  created_at timestamptz not null default now(),
  expires_at timestamptz not null default (now() + interval '14 days'),
  redeemed_by uuid references auth.users (id),
  redeemed_at timestamptz
);

alter table public.companion_invites enable row level security;
create policy "Invite owner can manage" on public.companion_invites
  for all using (auth.uid() = inviter_id) with check (auth.uid() = inviter_id);
create policy "Anyone authenticated can look up an invite by code" on public.companion_invites
  for select using (auth.role() = 'authenticated');

create table if not exists public.companions (
  id uuid primary key default gen_random_uuid(),
  user_a uuid not null references auth.users (id) on delete cascade,
  user_b uuid not null references auth.users (id) on delete cascade,
  created_at timestamptz not null default now(),
  constraint companions_distinct check (user_a <> user_b)
);

alter table public.companions enable row level security;
create policy "Companions are visible to both members" on public.companions
  for select using (auth.uid() in (user_a, user_b));
create policy "Companions insertable by either member" on public.companions
  for insert with check (auth.uid() in (user_a, user_b));
create policy "Companions deletable by either member" on public.companions
  for delete using (auth.uid() in (user_a, user_b));

create table if not exists public.companion_checkins (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users (id) on delete cascade,
  companion_id uuid not null references public.companions (id) on delete cascade,
  status text not null check (status in ('prayed', 'later', 'missed')),
  created_at timestamptz not null default now()
);

alter table public.companion_checkins enable row level security;
create policy "Checkins visible to companion pair" on public.companion_checkins
  for select using (
    exists (
      select 1 from public.companions c
      where c.id = companion_id and auth.uid() in (c.user_a, c.user_b)
    )
  );
create policy "Checkins insertable by self" on public.companion_checkins
  for insert with check (auth.uid() = user_id);

-- ---------------------------------------------------------------------------
-- Challenges (Phase 2)
-- ---------------------------------------------------------------------------
create table if not exists public.challenge_progress (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users (id) on delete cascade,
  challenge_key text not null,
  name text not null,
  total_days integer not null,
  current_day integer not null default 0,
  companion_id uuid references public.companions (id),
  started_at timestamptz not null default now(),
  active boolean not null default true
);

alter table public.challenge_progress enable row level security;
create policy "Challenge progress is owner-only" on public.challenge_progress
  for all using (auth.uid() = user_id) with check (auth.uid() = user_id);

-- ---------------------------------------------------------------------------
-- Reading plans (Phase 2)
-- ---------------------------------------------------------------------------
create table if not exists public.reading_plan_progress (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users (id) on delete cascade,
  plan_key text not null,
  pct numeric not null default 0,
  active boolean not null default false,
  unique (user_id, plan_key)
);

alter table public.reading_plan_progress enable row level security;
create policy "Reading plan progress is owner-only" on public.reading_plan_progress
  for all using (auth.uid() = user_id) with check (auth.uid() = user_id);

-- ---------------------------------------------------------------------------
-- Fasting sessions (Phase 2)
-- ---------------------------------------------------------------------------
create table if not exists public.fasting_sessions (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users (id) on delete cascade,
  started_at timestamptz not null default now(),
  ended_at timestamptz,
  target_hours numeric not null default 12
);

alter table public.fasting_sessions enable row level security;
create policy "Fasting sessions are owner-only" on public.fasting_sessions
  for all using (auth.uid() = user_id) with check (auth.uid() = user_id);

-- ---------------------------------------------------------------------------
-- Groups (Phase 3 — reference data + membership)
-- ---------------------------------------------------------------------------
create table if not exists public.groups (
  id uuid primary key default gen_random_uuid(),
  name text not null,
  meeting_time text,
  created_by uuid references auth.users (id),
  created_at timestamptz not null default now()
);

alter table public.groups enable row level security;
create policy "Groups are visible to members" on public.groups
  for select using (
    exists (select 1 from public.group_members m where m.group_id = id and m.user_id = auth.uid())
  );
create policy "Groups are creatable by any authenticated user" on public.groups
  for insert with check (auth.uid() = created_by);

create table if not exists public.group_members (
  group_id uuid not null references public.groups (id) on delete cascade,
  user_id uuid not null references auth.users (id) on delete cascade,
  joined_at timestamptz not null default now(),
  primary key (group_id, user_id)
);

alter table public.group_members enable row level security;
create policy "Group members visible to group members" on public.group_members
  for select using (
    exists (select 1 from public.group_members m2 where m2.group_id = group_id and m2.user_id = auth.uid())
  );
create policy "Users can join/leave for themselves" on public.group_members
  for all using (auth.uid() = user_id) with check (auth.uid() = user_id);

-- ---------------------------------------------------------------------------
-- Subscriptions / premium (Phase 1 upgrade screen)
-- ---------------------------------------------------------------------------
create table if not exists public.subscriptions (
  user_id uuid primary key references auth.users (id) on delete cascade,
  tier text not null default 'free' check (tier in ('free', 'premium')),
  provider text,
  renews_at timestamptz,
  updated_at timestamptz not null default now()
);

alter table public.subscriptions enable row level security;
create policy "Subscriptions are owner-only" on public.subscriptions
  for all using (auth.uid() = user_id) with check (auth.uid() = user_id);
