-- profiles' RLS only lets a user see their own row (or a paired companion's)
-- — since sermon sharing works between ANY two users, not just companions,
-- the recipient's client can't join sermon_shares -> profiles to read the
-- sender's name without a wider (and riskier) RLS policy. Denormalizing a
-- snapshot of the sender's name onto the share row at send time avoids that
-- entirely, the same trick already used for sermon_notes.shared_from_name.
alter table public.sermon_shares
  add column if not exists sender_name text;
