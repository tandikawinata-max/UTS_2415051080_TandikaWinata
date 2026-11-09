import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/body_measurement.dart';

class MeasurementService {
  final SupabaseClient _client;
  final String userId;

  MeasurementService(this._client, this.userId);

  void _ensureSession() {
    if (_client.auth.currentUser?.id != userId) {
      throw StateError('Sesi pengguna berubah. Silakan masuk kembali.');
    }
  }

  Future<List<Map<String, dynamic>>> fetchMeasurements() async {
    _ensureSession();

    return await _client
        .from('body_measurements')
        .select()
        .eq('user_id', userId)
        .order('measured_at', ascending: false)
        .order('id')
        .timeout(const Duration(seconds: 15));
  }

  Future<Map<String, dynamic>> insertMeasurement(
    BodyMeasurement measurement,
  ) async {
    _ensureSession();

    final input = measurement.toInsertJson();

    final payload = {...input, 'user_id': userId};

    try {
      return await _client
          .from('body_measurements')
          .insert(payload)
          .select()
          .single()
          .timeout(const Duration(seconds: 15));
    } on PostgrestException catch (error) {
      // ID mungkin sudah tersimpan ketika respons percobaan
      // sebelumnya tidak sampai ke aplikasi.
      if (error.code != '23505') rethrow;

      _ensureSession();

      final existing = await _client
          .from('body_measurements')
          .select()
          .eq('id', measurement.id)
          .eq('user_id', userId)
          .maybeSingle()
          .timeout(const Duration(seconds: 15));

      if (existing == null) rethrow;

      final savedInput = BodyMeasurement.fromJson(existing).toInsertJson();

      final sameInput = input.entries.every(
        (entry) => savedInput[entry.key] == entry.value,
      );

      if (!sameInput) {
        throw const MeasurementSaveConflict();
      }

      return existing;
    }
  }
}
