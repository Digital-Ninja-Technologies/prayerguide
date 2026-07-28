-- Prayer requests move from client-side E2E-encrypted text to plaintext,
-- server-readable columns (still gated by RLS). This is a deliberate
-- product trade-off: the app now supports sharing a request with your
-- prayer companion, and there is no way for a companion's device to
-- decrypt content encrypted with your device's private key under the old
-- per-device AES scheme — that would need a real multi-recipient
-- encryption design. Journal entries are untouched and remain end-to-end
-- encrypted; sharing was never part of that feature.
--
-- Caveat: any existing title_cipher/note_cipher content is unrecoverable
-- server-side by definition — that was the whole point of E2E encryption.
-- Rows created before this migration will carry an empty title until
-- edited or recreated.

alter table public.prayer_requests add column if not exists title text;
alter table public.prayer_requests add column if not exists note text;

update public.prayer_requests set title = '' where title is null;

alter table public.prayer_requests alter column title set not null;
alter table public.prayer_requests drop column if exists title_cipher;
alter table public.prayer_requests drop column if exists note_cipher;

-- Lets a paired companion see requests you've explicitly marked shared.
drop policy if exists "Shared requests are visible to a paired companion" on public.prayer_requests;
create policy "Shared requests are visible to a paired companion" on public.prayer_requests
  for select using (
    shared_with_companion = true
    and exists (
      select 1 from public.companions c
      where (c.user_a = auth.uid() and c.user_b = user_id)
         or (c.user_b = auth.uid() and c.user_a = user_id)
    )
  );
