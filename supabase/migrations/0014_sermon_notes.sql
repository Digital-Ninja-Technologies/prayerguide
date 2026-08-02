-- Sermon Note Taker: audio recording + written notes, optimized for taking
-- notes live during a sermon (type while recording, or type-only).
create table if not exists public.sermon_notes (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users (id) on delete cascade,
  title text not null,
  speaker text,
  scripture_ref text,
  notes text not null default '',
  audio_path text,
  audio_duration_seconds int,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

alter table public.sermon_notes enable row level security;
drop policy if exists "Sermon notes are owner-only" on public.sermon_notes;
create policy "Sermon notes are owner-only" on public.sermon_notes
  for all using (auth.uid() = user_id) with check (auth.uid() = user_id);

-- Recordings live at "<uid>/<sermon_note id>.m4a" in a private bucket —
-- nobody but the owner (via RLS on storage.objects below) can read them.
-- Not public: playback goes through a short-lived signed URL instead.
insert into storage.buckets (id, name, public)
  values ('sermon-audio', 'sermon-audio', false)
  on conflict (id) do nothing;

drop policy if exists "Sermon audio is owner-only" on storage.objects;
create policy "Sermon audio is owner-only" on storage.objects
  for all using (
    bucket_id = 'sermon-audio' and (storage.foldername(name))[1] = auth.uid()::text
  ) with check (
    bucket_id = 'sermon-audio' and (storage.foldername(name))[1] = auth.uid()::text
  );
