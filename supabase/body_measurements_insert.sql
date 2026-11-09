begin;

grant insert on table public.body_measurements
  to authenticated;

drop policy if exists "Insert own body measurements"
  on public.body_measurements;

create policy "Insert own body measurements"
  on public.body_measurements
  for insert
  to authenticated
  with check ((select auth.uid()) = user_id);

commit;