-- A second, distinct streak: consecutive days the app was *opened*, whether
-- or not a prayer session happened that day. Mirrors the prayer_sessions /
-- handle_prayer_session pattern exactly (same consecutive-day logic), just
-- keyed off a lightweight app_opens table instead of prayer_sessions.
alter table public.profiles
  add column if not exists app_open_streak_count integer not null default 0,
  add column if not exists app_open_longest_streak integer not null default 0,
  add column if not exists last_opened_on date;

create table if not exists public.app_opens (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users (id) on delete cascade,
  opened_at timestamptz not null default now()
);

alter table public.app_opens enable row level security;
drop policy if exists "App opens are owner-only" on public.app_opens;
create policy "App opens are owner-only" on public.app_opens
  for all using (auth.uid() = user_id) with check (auth.uid() = user_id);

create or replace function public.handle_app_open()
returns trigger
language plpgsql
security definer set search_path = public
as $$
declare
  today date := (new.opened_at at time zone 'utc')::date;
  prev date;
  cur_count integer;
  cur_longest integer;
begin
  select last_opened_on, app_open_streak_count, app_open_longest_streak
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
    set app_open_streak_count = cur_count,
        app_open_longest_streak = greatest(coalesce(cur_longest, 0), cur_count),
        last_opened_on = today
    where id = new.user_id;

  return new;
end;
$$;

drop trigger if exists on_app_open_insert on public.app_opens;
create trigger on_app_open_insert
  after insert on public.app_opens
  for each row execute procedure public.handle_app_open();
