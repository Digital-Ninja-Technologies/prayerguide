-- Wrapped copy of each user's client-side encryption key (see
-- lib/core/security/encryption_service.dart), so it can be recovered on a
-- new device or after a reinstall — *only* by someone who knows the user's
-- recovery passphrase. The server stores nothing that lets it, or anyone
-- without the passphrase, unwrap the key: `wrapped_key` is the raw AES-256
-- data key encrypted with a key derived from the passphrase via PBKDF2
-- (`salt`, `iterations`). This is opt-in — until a user sets a recovery
-- passphrase, their key stays device-only, as before.
create table if not exists public.encryption_keys (
  user_id uuid primary key references auth.users (id) on delete cascade,
  wrapped_key text not null,
  salt text not null,
  iterations integer not null default 200000,
  updated_at timestamptz not null default now()
);

alter table public.encryption_keys enable row level security;
drop policy if exists "Encryption key escrow is owner-only" on public.encryption_keys;
create policy "Encryption key escrow is owner-only" on public.encryption_keys
  for all using (auth.uid() = user_id) with check (auth.uid() = user_id);
