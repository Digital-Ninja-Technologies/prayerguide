-- Self-service account deletion (Apple App Store Review Guideline 5.1.1(v)
-- requires this for any app that supports account creation — "email us"
-- alone isn't sufficient).
--
-- Almost every table's user_id already cascades on auth.users deletion, so
-- deleting the auth.users row itself is enough to clean up the rest. Two
-- foreign keys don't cascade, which would otherwise block deletion outright
-- for anyone who's ever created a group or redeemed a companion invite:
--
--   groups.created_by         — the group and its other members shouldn't
--                                disappear just because the creator left, so
--                                this clears the reference instead of
--                                cascading the delete.
--   companion_invites.redeemed_by — same reasoning; the invite record and
--                                the inviter's history stay intact.
alter table public.groups drop constraint if exists groups_created_by_fkey;
alter table public.groups add constraint groups_created_by_fkey
  foreign key (created_by) references auth.users (id) on delete set null;

alter table public.companion_invites drop constraint if exists companion_invites_redeemed_by_fkey;
alter table public.companion_invites add constraint companion_invites_redeemed_by_fkey
  foreign key (redeemed_by) references auth.users (id) on delete set null;

-- SECURITY DEFINER so it can delete the caller's own auth.users row (a
-- privilege the `authenticated` role doesn't otherwise have) — it only ever
-- targets auth.uid() itself, never an arbitrary id, so this doesn't grant
-- anyone the ability to delete anyone else's account.
--
-- Known limitation: this cleans up every database row (via cascade) but not
-- the user's files in the sermon-audio storage bucket — those become
-- unreachable (still folder-scoped to their now-nonexistent uid, so nobody
-- can read them) but aren't physically removed. Acceptable for now; a
-- scheduled cleanup job could reap orphaned storage folders later if the
-- storage cost becomes worth addressing.
create or replace function public.delete_own_account()
returns void
language plpgsql
security definer set search_path = public
as $$
begin
  delete from auth.users where id = auth.uid();
end;
$$;

grant execute on function public.delete_own_account() to authenticated;
