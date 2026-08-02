-- group_members' own "visible to group members" policy queried
-- group_members from inside its own USING clause — a self-referential
-- subquery that Postgres's RLS planner can't resolve, since checking the
-- policy re-triggers the same policy on the subquery, forever
-- ("infinite recursion detected in policy for relation group_members",
-- 42P17). This was never caught because Groups had no navigation entry
-- point in the app until now, so the query never actually ran.
--
-- Standard fix: move the membership check into a SECURITY DEFINER
-- function. Running it as the function owner (bypassing RLS internally)
-- breaks the recursive re-evaluation while still only ever answering "is
-- this specific user in this specific group" — no broader access is
-- granted than the original policy intended.
create or replace function public.is_group_member(gid uuid, uid uuid)
returns boolean
language sql
security definer
stable
set search_path = public
as $$
  select exists (
    select 1 from public.group_members gm
    where gm.group_id = gid and gm.user_id = uid
  );
$$;

grant execute on function public.is_group_member(uuid, uuid) to authenticated;

drop policy if exists "Group members visible to group members" on public.group_members;
create policy "Group members visible to group members" on public.group_members
  for select using (
    public.is_group_member(group_id, auth.uid())
  );
