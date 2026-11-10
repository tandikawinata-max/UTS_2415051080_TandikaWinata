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
  values ('Uji UPDATE akun B', 100)
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
  saved_chest numeric;
  changed_rows integer;
  owner_change_rejected boolean := false;
begin
  insert into public.body_measurements (label, chest_cm)
  values ('Uji UPDATE akun A', 94)
  returning id into own_id;

  update public.body_measurements
  set chest_cm = 95, waist_cm = null
  where id = own_id
  returning chest_cm into saved_chest;

  if saved_chest is distinct from 95 then
    raise exception 'GAGAL: profil sendiri tidak diperbarui.';
  end if;

  update public.body_measurements
  set chest_cm = 999
  where id = current_setting('usize.test.profile_b')::uuid;

  get diagnostics changed_rows = row_count;

  if changed_rows <> 0 then
    raise exception 'GAGAL: profil akun lain dapat diperbarui.';
  end if;

  begin
    update public.body_measurements
    set user_id = current_setting('usize.test.user_b')::uuid
    where id = own_id;
  exception
    when insufficient_privilege then
      owner_change_rejected := true;
  end;

  if not owner_change_rejected then
    raise exception 'GAGAL: pemilik profil dapat diganti.';
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
    raise exception 'GAGAL: data akun B berubah atau hilang.';
  end if;
end;
$verify$;

select
  'LULUS: edit sendiri berhasil, akun lain terlindungi, pemilik tetap.'
  as hasil_pengujian;

rollback;