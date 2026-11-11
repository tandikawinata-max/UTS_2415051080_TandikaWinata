begin;

create table if not exists public.fit_analyses (
  id uuid primary key,
  user_id uuid not null default auth.uid() references auth.users(id) on delete cascade,
  title text not null check (char_length(btrim(title)) between 1 and 80),
  created_at timestamptz not null default now(),
  payload jsonb not null,
  profile_label text generated always as (payload -> 'profile' ->> 'label') stored not null,
  chart_basis text generated always as (payload ->> 'basis') stored not null,
  recommended_labels jsonb generated always as (payload -> 'recommended_labels') stored not null,
  constraint fit_analyses_payload_valid check (
    jsonb_typeof(payload) = 'object'
    and payload ?& array['schema_version', 'rule_version', 'analyzed_at', 'profile',
      'basis', 'unit', 'input_rows', 'evaluations', 'recommended_labels', 'notes']
    and payload ->> 'schema_version' is not null
    and payload ->> 'schema_version' = '1'
    and jsonb_typeof(payload -> 'profile') = 'object'
    and jsonb_typeof(payload -> 'input_rows') = 'array'
    and jsonb_typeof(payload -> 'evaluations') = 'array'
    and jsonb_array_length(payload -> 'input_rows') > 0
    and jsonb_array_length(payload -> 'evaluations') > 0
    and jsonb_typeof(recommended_labels) = 'array'
    and chart_basis in ('body', 'garment')
    and octet_length(payload::text) <= 262144
  )
);

create index if not exists fit_analyses_user_date_id_idx
  on public.fit_analyses(user_id, created_at desc, id desc);
alter table public.fit_analyses enable row level security;
grant usage on schema public to authenticated;
revoke all on public.fit_analyses from public, anon, authenticated;
grant select, delete on public.fit_analyses to authenticated;
grant insert(id, user_id, title, payload) on public.fit_analyses to authenticated;

drop policy if exists "Read own fit analyses" on public.fit_analyses;
create policy "Read own fit analyses" on public.fit_analyses
  for select to authenticated using ((select auth.uid()) = user_id);
drop policy if exists "Insert own fit analyses" on public.fit_analyses;
create policy "Insert own fit analyses" on public.fit_analyses
  for insert to authenticated with check ((select auth.uid()) = user_id);
drop policy if exists "Delete own fit analyses" on public.fit_analyses;
create policy "Delete own fit analyses" on public.fit_analyses
  for delete to authenticated using ((select auth.uid()) = user_id);

-- No UPDATE permission: historical results are immutable. Profile IDs inside the
-- JSON snapshot intentionally have no FK; deleting a profile preserves history.
commit;
