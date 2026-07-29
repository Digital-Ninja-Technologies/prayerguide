-- The passphrase-based recovery/escrow scheme is replaced by cloud backup
-- (iCloud Keychain sync on iOS, Google Drive appDataFolder on Android) —
-- both handled entirely client-side, so Supabase never holds the key or a
-- wrapped copy of it at all now. Drop the now-unused escrow table.
--
-- Caveat: anyone who only ever set up the old passphrase recovery (never
-- unlocked on a second device) loses that recovery path — there was no way
-- to migrate a passphrase-wrapped key into the new scheme without asking
-- for the passphrase again, and the new scheme doesn't use passphrases.
drop table if exists public.encryption_keys;
