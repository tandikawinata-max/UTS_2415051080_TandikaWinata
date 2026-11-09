begin;

select set_config(
  'request.jwt.claim.sub',
  'UUID_A',
  true
);

select set_config(
  'usize.test.other_user_id',
  'UUID_B',
  true
);

set local role authenticated;

do $test$
declare
  saved_owner uuid;
  rejected boolean := false;
begin
  insert into public.body_measurements (
    user_id,
    label,
    chest_cm
  )
  values (
    auth.uid(),
    'Uji INSERT milik sendiri',
    94
  )
  returning user_id into saved_owner;

  if saved_owner is distinct from auth.uid() then
    raise exception 'GAGAL: pemilik profil tidak sesuai.';
  end if;

  begin
    insert into public.body_measurements (
      user_id,
      label,
      chest_cm
    )
    values (
      current_setting('usize.test.other_user_id')::uuid,
      'Uji INSERT untuk akun lain',
      94
    );
  exception
    when insufficient_privilege then
      rejected := true;
  end;

  if not rejected then
    raise exception 'GAGAL: INSERT untuk akun lain diizinkan.';
  end if;
end;
$test$;

select
  'LULUS: INSERT milik sendiri diterima dan akun lain ditolak.'
  as hasil_pengujian;

rollback;