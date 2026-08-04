-- Morning/evening prayer reminders had a single time that applied every
-- day. Users want a different time per day of the week (e.g. a later
-- morning reminder on weekends), so the single `morning_prayer_time` /
-- `evening_prayer_time` columns become seven columns each, one per weekday.
-- The on/off toggles (morning_prayer / evening_prayer) stay global — only
-- the time varies by day.

alter table public.notification_prefs
  add column if not exists morning_time_mon time not null default '06:30',
  add column if not exists morning_time_tue time not null default '06:30',
  add column if not exists morning_time_wed time not null default '06:30',
  add column if not exists morning_time_thu time not null default '06:30',
  add column if not exists morning_time_fri time not null default '06:30',
  add column if not exists morning_time_sat time not null default '06:30',
  add column if not exists morning_time_sun time not null default '06:30',
  add column if not exists evening_time_mon time not null default '20:00',
  add column if not exists evening_time_tue time not null default '20:00',
  add column if not exists evening_time_wed time not null default '20:00',
  add column if not exists evening_time_thu time not null default '20:00',
  add column if not exists evening_time_fri time not null default '20:00',
  add column if not exists evening_time_sat time not null default '20:00',
  add column if not exists evening_time_sun time not null default '20:00';

-- Carry forward each existing user's single time into every day, rather
-- than silently resetting everyone to the schema default above.
update public.notification_prefs set
  morning_time_mon = morning_prayer_time,
  morning_time_tue = morning_prayer_time,
  morning_time_wed = morning_prayer_time,
  morning_time_thu = morning_prayer_time,
  morning_time_fri = morning_prayer_time,
  morning_time_sat = morning_prayer_time,
  morning_time_sun = morning_prayer_time,
  evening_time_mon = evening_prayer_time,
  evening_time_tue = evening_prayer_time,
  evening_time_wed = evening_prayer_time,
  evening_time_thu = evening_prayer_time,
  evening_time_fri = evening_prayer_time,
  evening_time_sat = evening_prayer_time,
  evening_time_sun = evening_prayer_time;

alter table public.notification_prefs
  drop column if exists morning_prayer_time,
  drop column if exists evening_prayer_time;
