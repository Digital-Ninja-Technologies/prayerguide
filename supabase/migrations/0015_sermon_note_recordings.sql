-- Sermon notes originally supported a single recording per note (audio_path
-- on sermon_notes itself), with a "Re-record" action that discarded the
-- stopped take and started over. That let a user silently lose a take.
-- Moving to a child table: stopping a recording locks it in, and a new
-- "record a new one" action appends another row instead of overwriting —
-- both while composing a brand-new note and later from an existing one.
--
-- sermon_notes.audio_path/audio_duration_seconds are left in place (unused
-- going forward) rather than dropped, since dropping columns is destructive
-- and this app has no migration-down story.
create table if not exists public.sermon_note_recordings (
  id uuid primary key default gen_random_uuid(),
  sermon_note_id uuid not null references public.sermon_notes (id) on delete cascade,
  audio_path text not null,
  duration_seconds int,
  created_at timestamptz not null default now()
);

alter table public.sermon_note_recordings enable row level security;
drop policy if exists "Sermon note recordings are owner-only" on public.sermon_note_recordings;
create policy "Sermon note recordings are owner-only" on public.sermon_note_recordings
  for all using (
    exists (
      select 1 from public.sermon_notes sn
      where sn.id = sermon_note_id and sn.user_id = auth.uid()
    )
  ) with check (
    exists (
      select 1 from public.sermon_notes sn
      where sn.id = sermon_note_id and sn.user_id = auth.uid()
    )
  );
