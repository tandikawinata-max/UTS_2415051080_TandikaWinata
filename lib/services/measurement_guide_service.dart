import 'dart:convert';

import 'package:http/http.dart' as http;

import '../models/measurement_guide.dart';

class MeasurementGuideService {
  final http.Client _client;
  final String _baseUrl;
  final String _publishableKey;

  MeasurementGuideService({
    http.Client? client,
    String? baseUrl,
    String? publishableKey,
  }) : _client = client ?? http.Client(),
       _baseUrl = baseUrl ?? const String.fromEnvironment('SUPABASE_URL'),
       _publishableKey =
           publishableKey ??
           const String.fromEnvironment('SUPABASE_PUBLISHABLE_KEY');

  Future<List<MeasurementGuide>> fetchGuides() async {
    final baseUri = Uri.tryParse(_baseUrl.trim());
    final key = _publishableKey.trim();

    if (baseUri == null ||
        baseUri.scheme != 'https' ||
        baseUri.host.isEmpty ||
        !key.startsWith('sb_publishable_')) {
      throw StateError(
        'Konfigurasi Supabase belum sesuai. '
        'Periksa SUPABASE_URL dan SUPABASE_PUBLISHABLE_KEY.',
      );
    }

    final uri = baseUri.replace(
      path: '/rest/v1/measurement_guides',
      queryParameters: {
        'select':
            'id,measurement_key,title,instruction,unit,category,sort_order',
        'category': 'eq.tops',
        'is_published': 'eq.true',
        'order': 'sort_order.asc,id.asc',
      },
    );

    final response = await _client
        .get(uri, headers: {'apikey': key, 'Accept': 'application/json'})
        .timeout(const Duration(seconds: 15));

    if (response.statusCode != 200) {
      throw Exception('Permintaan panduan gagal: HTTP ${response.statusCode}.');
    }

    final Object? decoded = jsonDecode(utf8.decode(response.bodyBytes));

    if (decoded is! List) {
      throw const FormatException('Respons panduan harus berupa daftar JSON.');
    }

    return decoded
        .map<MeasurementGuide>((item) {
          if (item is! Map<String, dynamic>) {
            throw const FormatException(
              'Setiap panduan harus berupa objek JSON.',
            );
          }

          return MeasurementGuide.fromJson(item);
        })
        .toList(growable: false);
  }

  void dispose() {
    _client.close();
  }
}
