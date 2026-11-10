begin;

revoke update on table public.body_measurements
  from public, anon, authenticated;

revoke update (id, user_id, created_at)
  on table public.body_measurements
  from public, anon, authenticated;

grant update (
  label,
  chest_cm,
  waist_cm,
  hip_cm,
  shoulder_width_cm,
  height_cm,
  weight_kg,
  measured_at
)
on table public.body_measurements
to authenticated;

drop policy if exists "Update own body measurements"
  on public.body_measurements;

create policy "Update own body measurements"
  on public.body_measurements
  for update
  to authenticated
  using ((select auth.uid()) = user_id)
  with check ((select auth.uid()) = user_id);

commit;