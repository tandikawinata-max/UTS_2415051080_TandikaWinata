begin;

set local role authenticated;

select set_config('request.jwt.claim.sub', 'UUID_B', true);

select set_config(
  'usize.test.user_b',
  auth.uid()::text,
  true
);

with inserted as (
  insert into public.body_measurements (label, chest_cm)
  values ('Uji DELETE akun B', 100)
  returning id
)
select set_config(
  'usize.test.profile_b',
  id::text,
  true
)
from inserted;

select set_config('request.jwt.claim.sub', 'UUID_A', true);

do $test$
declare
  own_id uuid;
  deleted_id uuid;
  changed_rows integer;
begin
  insert into public.body_measurements (label, chest_cm)
  values ('Uji DELETE akun A', 94)
  returning id into own_id;

  delete from public.body_measurements
  where id = own_id
  returning id into deleted_id;

  if deleted_id is distinct from own_id then
    raise exception 'GAGAL: profil sendiri tidak terhapus.';
  end if;

  if exists (
    select 1
    from public.body_measurements
    where id = own_id
  ) then
    raise exception 'GAGAL: profil sendiri masih tersedia.';
  end if;

  delete from public.body_measurements
  where id = current_setting('usize.test.profile_b')::uuid;

  get diagnostics changed_rows = row_count;

  if changed_rows <> 0 then
    raise exception 'GAGAL: profil akun lain dapat dihapus.';
  end if;

  if has_table_privilege(
    'anon',
    'public.body_measurements',
    'DELETE'
  ) then
    raise exception 'GAGAL: role anon memiliki izin DELETE.';
  end if;
end;
$test$;

select set_config(
  'request.jwt.claim.sub',
  current_setting('usize.test.user_b'),
  true
);

do $verify$
begin
  if not exists (
    select 1
    from public.body_measurements
    where id = current_setting('usize.test.profile_b')::uuid
      and chest_cm = 100
  ) then
    raise exception 'GAGAL: profil akun B berubah atau hilang.';
  end if;
end;
$verify$;

select
  'LULUS: hapus sendiri berhasil, akun lain terlindungi, anon ditolak.'
  as hasil_pengujian;

rollback;