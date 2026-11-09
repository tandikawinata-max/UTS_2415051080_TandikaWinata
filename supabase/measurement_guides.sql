begin;

create table if not exists public.measurement_guides (
  id text primary key,
  measurement_key text not null,
  title text not null,
  instruction text not null,
  unit text not null default 'cm',
  category text not null default 'tops',
  sort_order integer not null default 0,
  is_published boolean not null default true
);

alter table public.measurement_guides
  enable row level security;

grant usage on schema public to anon, authenticated;

revoke all on table public.measurement_guides
  from anon, authenticated;

grant select on table public.measurement_guides
  to anon, authenticated;

drop policy if exists "Read published measurement guides"
  on public.measurement_guides;

create policy "Read published measurement guides"
  on public.measurement_guides
  for select
  to anon, authenticated
  using (is_published = true);

insert into public.measurement_guides (
  id,
  measurement_key,
  title,
  instruction,
  unit,
  category,
  sort_order,
  is_published
)
values
  (
    'tops-chest',
    'chest_cm',
    'Lingkar dada',
    'Lingkarkan pita ukur pada bagian dada yang paling penuh. Pastikan pita tetap mendatar, tidak terpuntir, dan tidak menekan tubuh. Berdiri rileks saat membaca hasil.',
    'cm',
    'tops',
    1,
    true
  ),
  (
    'tops-waist',
    'waist_cm',
    'Lingkar pinggang',
    'Lingkarkan pita ukur pada pinggang alami, biasanya di bagian tubuh yang paling ramping di antara tulang rusuk dan panggul. Bernapas normal dan jangan menarik perut ke dalam.',
    'cm',
    'tops',
    2,
    true
  ),
  (
    'tops-hip',
    'hip_cm',
    'Lingkar pinggul',
    'Berdiri dengan kedua kaki berdekatan. Lingkarkan pita ukur melalui bagian pinggul dan bokong yang paling penuh. Pastikan pita mendatar ketika membaca hasil.',
    'cm',
    'tops',
    3,
    true
  ),
  (
    'tops-shoulder',
    'shoulder_width_cm',
    'Lebar bahu',
    'Ukur dari ujung bahu kiri ke ujung bahu kanan melalui bagian belakang tubuh. Minta bantuan orang lain agar posisi pita sesuai. Catat sebagai lebar, bukan lingkar.',
    'cm',
    'tops',
    4,
    true
  )
on conflict (id) do nothing;

commit;