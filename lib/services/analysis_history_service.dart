import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/analysis_history.dart';

class AnalysisHistoryService {
  final SupabaseClient _client;
  final String userId;
  static const pageSize = 20;
  static const _timeout = Duration(seconds: 15);
  AnalysisHistoryService(this._client, this.userId);

  void _ensureSession() {
    if (_client.auth.currentUser?.id != userId) {
      throw const AnalysisHistoryUnavailable();
    }
  }

  Future<List<Map<String, dynamic>>> fetchPage({
    AnalysisHistoryCursor? after,
  }) async {
    _ensureSession();
    var query = _client
        .from('fit_analyses')
        .select(
          'id,title,created_at,profile_label,chart_basis,recommended_labels',
        )
        .eq('user_id', userId);
    if (after != null) {
      // Cursor values originate from typed server dates and UUID identifiers.
      if (!RegExp(r'^[0-9a-fA-F-]{36}$').hasMatch(after.id)) {
        throw const FormatException(
          'Penanda halaman tidak valid. Muat ulang riwayat.',
        );
      }
      final date = after.createdAt.toUtc().toIso8601String();
      query = query.or(
        'created_at.lt.$date,and(created_at.eq.$date,id.lt.${after.id})',
      );
    }
    final rows = await query
        .order('created_at', ascending: false)
        .order('id', ascending: false)
        .limit(pageSize + 1)
        .timeout(_timeout);
    _ensureSession();
    return rows;
  }

  Future<Map<String, dynamic>?> findById(String id) async {
    _ensureSession();
    final row = await _client
        .from('fit_analyses')
        .select()
        .eq('user_id', userId)
        .eq('id', id)
        .maybeSingle()
        .timeout(_timeout);
    _ensureSession();
    return row;
  }

  Future<Map<String, dynamic>> save(AnalysisHistoryDraft draft) async {
    _ensureSession();
    try {
      final row = await _client
          .from('fit_analyses')
          .insert({...draft.toJson(), 'user_id': userId})
          .select()
          .single()
          .timeout(_timeout);
      _ensureSession();
      return row;
    } on PostgrestException catch (error) {
      if (error.code != '23505') rethrow;
      // Reusing the result ID makes retries safe after a lost success response.
      final existing = await findById(draft.id);
      if (existing == null ||
          !draft.matches(AnalysisHistoryEntry.fromJson(existing))) {
        throw const AnalysisHistoryConflict();
      }
      return existing;
    }
  }

  Future<void> delete(String id) async {
    _ensureSession();
    final deleted = await _client
        .from('fit_analyses')
        .delete()
        .eq('user_id', userId)
        .eq('id', id)
        .select('id')
        .maybeSingle()
        .timeout(_timeout);
    _ensureSession();
    // An already deleted record is a successful retry only after a server read.
    if (deleted == null && await findById(id) != null) {
      throw const AnalysisHistoryUnavailable();
    }
  }
}
