-- Creating a group does `insert(...).select().single()` — an INSERT ...
-- RETURNING under the hood. Postgres applies the table's SELECT policy to
-- rows read back via RETURNING, and the creator's `group_members` row
-- isn't inserted until the *next* statement, so the brand-new group was
-- invisible to its own creator at that instant ("new row violates row-
-- level security policy for table groups", 42501 — never caught before
-- since Groups had no navigation entry point until now).
--
-- Fix: the creator can always see a group they created, independent of
-- group_members — a reasonable rule on its own, not just a RETURNING
-- workaround (e.g. it also keeps a group visible to its creator if the
-- membership insert ever fails after this one succeeds).
drop policy if exists "Groups are visible to members" on public.groups;
create policy "Groups are visible to members" on public.groups
  for select using (
    created_by = auth.uid()
    or exists (select 1 from public.group_members m where m.group_id = id and m.user_id = auth.uid())
  );
