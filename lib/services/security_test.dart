import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

Future<void> runSecurityTest({
  required int courseIdMilikUserA,
  required String uuidUserA,
}) async {
  final client = Supabase.instance.client;
  debugPrint('=== MULAI SECURITY TEST (LOGIN SEBAGAI USER B) ===');

  // 1. User B mencoba mengubah data User A -> harus DENIED (0 baris berubah)
  final updatedRows = await client
      .from('courses')
      .update({'title': 'DIUBAH SECARA ILEGAL OLEH USER B'})
      .eq('id', courseIdMilikUserA)
      .select();

  debugPrint(
    updatedRows.isNotEmpty
        ? '[FAIL] User B berhasil mengubah data User A'
        : '[PASS] UPDATE ditolak oleh RLS (0 rows affected)',
  );

  // 2. User B mencoba menghapus data User A -> harus DENIED (0 baris terhapus)
  final deletedRows = await client
      .from('courses')
      .delete()
      .eq('id', courseIdMilikUserA)
      .select();

  debugPrint(
    deletedRows.isNotEmpty
        ? '[FAIL] User B berhasil menghapus data User A'
        : '[PASS] DELETE ditolak oleh RLS (0 rows affected)',
  );

  // 3. User B mencoba INSERT memalsukan owner_id milik User A -> harus ERROR 42501
  try {
    await client.from('courses').insert({
      'owner_id': uuidUserA,
      'title': 'Course Palsu Atas Nama User A',
      'code': 'HACK101',
      'credits': 3,
      'status': 'Aktif',
    });
    debugPrint('[FAIL] INSERT atas nama user lain berhasil');
  } on PostgrestException catch (e) {
    debugPrint('[PASS] INSERT ditolak oleh RLS: ${e.code} - ${e.message}');
  }

  debugPrint('=== SELESAI SECURITY TEST ===');
}
