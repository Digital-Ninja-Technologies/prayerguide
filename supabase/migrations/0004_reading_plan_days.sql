-- Reading plans need a day counter, not just a raw percentage, so the app
-- can compute "today's reading" and advance it by exactly one day at a time.
alter table public.reading_plan_progress
  add column if not exists days_completed integer not null default 0;
