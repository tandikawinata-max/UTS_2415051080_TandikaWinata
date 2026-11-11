-- Run after fit_analyses.sql in SQL Editor. Requires two existing Auth users.
-- Test rows and settings are rolled back; existing user data is not modified.
begin;
do $setup$
declare a uuid; b uuid;
begin
  select id into a from auth.users order by id limit 1;
  select id into b from auth.users order by id offset 1 limit 1;
  if a is null or b is null then
    raise exception 'Buat minimal dua akun Auth untuk pengujian akses antar pengguna.';
  end if;
  perform set_config('usize.test.user_a', a::text, true);
  perform set_config('usize.test.user_b', b::text, true);
  perform set_config('usize.test.own_id', gen_random_uuid()::text, true);
  perform set_config('usize.test.other_id', gen_random_uuid()::text, true);
  perform set_config('usize.test.payload', '{"schema_version":1,"rule_version":"test",
    "analyzed_at":"2026-11-10T00:00:00Z","profile":{"label":"Profil uji"},
    "basis":"body","unit":"cm","input_rows":[{"label":"M","chest":"92-97"}],
    "evaluations":[{"label":"M"}],"recommended_labels":["M"],"notes":[]}', true);
  insert into public.fit_analyses(id,user_id,title,payload) values (
    current_setting('usize.test.other_id')::uuid, b, 'Riwayat uji B', current_setting('usize.test.payload')::jsonb);
end;
$setup$;

select set_config('request.jwt.claim.sub', current_setting('usize.test.user_a'), true);
set local role authenticated;
do $test$
declare count_rows integer; denied boolean;
begin
  insert into public.fit_analyses(id,user_id,title,payload) values (
    current_setting('usize.test.own_id')::uuid, auth.uid(), 'Riwayat uji A', current_setting('usize.test.payload')::jsonb);
  select count(*) into count_rows from public.fit_analyses where id = current_setting('usize.test.own_id')::uuid;
  if count_rows <> 1 then raise exception 'FAIL: akun A tidak dapat membaca hasil sendiri.'; end if;
  select count(*) into count_rows from public.fit_analyses where id = current_setting('usize.test.other_id')::uuid;
  if count_rows <> 0 then raise exception 'FAIL: akun A dapat membaca hasil B.'; end if;
  delete from public.fit_analyses where id = current_setting('usize.test.other_id')::uuid;
  get diagnostics count_rows = row_count;
  if count_rows <> 0 then raise exception 'FAIL: akun A dapat menghapus hasil B.'; end if;
  denied := false;
  begin
    insert into public.fit_analyses(id,user_id,title,payload) values (
      gen_random_uuid(), current_setting('usize.test.user_b')::uuid, 'Pemilik salah', current_setting('usize.test.payload')::jsonb);
  exception when insufficient_privilege then denied := true;
  end;
  if not denied then raise exception 'FAIL: akun A dapat menyimpan atas nama B.'; end if;
  denied := false;
  begin
    update public.fit_analyses set title = 'Diubah' where id = current_setting('usize.test.own_id')::uuid;
  exception when insufficient_privilege then denied := true;
  end;
  if not denied then raise exception 'FAIL: hasil historis dapat diubah.'; end if;
  denied := false;
  begin
    insert into public.fit_analyses(id,user_id,title,payload,created_at) values (
      gen_random_uuid(), auth.uid(), 'Tanggal palsu', current_setting('usize.test.payload')::jsonb, now());
  exception when insufficient_privilege then denied := true;
  end;
  if not denied then raise exception 'FAIL: waktu simpan dapat ditentukan klien.'; end if;
  delete from public.fit_analyses where id = current_setting('usize.test.own_id')::uuid;
  get diagnostics count_rows = row_count;
  if count_rows <> 1 then raise exception 'FAIL: hasil sendiri tidak dapat dihapus.'; end if;
end;
$test$;

reset role;
select set_config('request.jwt.claim.sub', current_setting('usize.test.user_b'), true);
set local role authenticated;
do $test$
begin
  if not exists(select 1 from public.fit_analyses where id = current_setting('usize.test.other_id')::uuid) then
    raise exception 'FAIL: hasil B hilang setelah percobaan hapus oleh A.';
  end if;
end;
$test$;

reset role;
set local role anon;
do $test$
declare denied boolean;
begin
  denied := false;
  begin perform 1 from public.fit_analyses;
  exception when insufficient_privilege then denied := true;
  end;
  if not denied then raise exception 'FAIL: anon dapat membaca riwayat.'; end if;
  denied := false;
  begin
    insert into public.fit_analyses(id,user_id,title,payload) values (
      gen_random_uuid(), current_setting('usize.test.user_a')::uuid, 'Anon', current_setting('usize.test.payload')::jsonb);
  exception when insufficient_privilege then denied := true;
  end;
  if not denied then raise exception 'FAIL: anon dapat menyimpan riwayat.'; end if;
  denied := false;
  begin delete from public.fit_analyses where id = current_setting('usize.test.other_id')::uuid;
  exception when insufficient_privilege then denied := true;
  end;
  if not denied then raise exception 'FAIL: anon dapat menghapus riwayat.'; end if;
end;
$test$;
reset role;
select 'LULUS: baca/simpan/hapus milik sendiri, isolasi akun, immutability, dan akses anon.' as hasil;
rollback;
