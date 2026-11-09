begin;

create table if not exists public.body_measurements (
  id uuid primary key default gen_random_uuid(),

  user_id uuid not null
    default auth.uid()
    references auth.users(id)
    on delete cascade,

  label text not null
    check (char_length(btrim(label)) between 1 and 80),

  chest_cm numeric(6, 2) not null
    check (chest_cm > 0),

  waist_cm numeric(6, 2)
    check (waist_cm > 0),

  hip_cm numeric(6, 2)
    check (hip_cm > 0),

  shoulder_width_cm numeric(6, 2)
    check (shoulder_width_cm > 0),

  height_cm numeric(6, 2)
    check (height_cm > 0),

  weight_kg numeric(6, 2)
    check (weight_kg > 0),

  measured_at timestamptz not null default now(),
  created_at timestamptz not null default now()
);

create index if not exists body_measurements_user_date_idx
  on public.body_measurements (user_id, measured_at desc);

alter table public.body_measurements
  enable row level security;

grant usage on schema public to authenticated;

revoke all on table public.body_measurements
  from public, anon, authenticated;

grant select on table public.body_measurements
  to authenticated;

drop policy if exists "Read own body measurements"
  on public.body_measurements;

create policy "Read own body measurements"
  on public.body_measurements
  for select
  to authenticated
  using ((select auth.uid()) = user_id);

commit;