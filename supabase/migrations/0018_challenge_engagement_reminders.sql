-- Tracks the last date a challenge's day was actually advanced, so a
-- reminder notification knows whether today's session still needs doing —
-- without this, the app has no way to tell "hasn't engaged today" apart
-- from "engaged this morning already".
alter table public.challenge_progress
  add column if not exists last_advanced_on date;

-- A dedicated on/off toggle for these reminders, alongside the app's other
-- notification preferences.
alter table public.notification_prefs
  add column if not exists challenge_reminders boolean not null default true;
