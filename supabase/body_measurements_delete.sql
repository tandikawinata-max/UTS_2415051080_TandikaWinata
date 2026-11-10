begin;

revoke delete on table public.body_measurements
  from public, anon, authenticated;

grant delete on table public.body_measurements
  to authenticated;

drop policy if exists "Delete own body measurements"
  on public.body_measurements;

create policy "Delete own body measurements"
  on public.body_measurements
  for delete
  to authenticated
  using ((select auth.uid()) = user_id);

commit;