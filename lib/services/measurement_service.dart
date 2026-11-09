import 'package:supabase_flutter/supabase_flutter.dart';

class MeasurementService {
  final SupabaseClient _client;
  final String userId;

  MeasurementService(this._client, this.userId);

  Future<List<Map<String, dynamic>>> fetchMeasurements() async {
    if (_client.auth.currentUser?.id != userId) {
      throw StateError('Sesi pengguna berubah. Silakan masuk kembali.');
    }

    final rows = await _client
        .from('body_measurements')
        .select()
        .eq('user_id', userId)
        .order('measured_at', ascending: false)
        .order('id')
        .timeout(const Duration(seconds: 15));

    return rows;
  }
}
