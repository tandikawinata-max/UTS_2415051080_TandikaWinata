import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:usize/repositories/measurement_guide_repository.dart';
import 'package:usize/screens/measurement_guide_screen.dart';
import 'package:usize/services/measurement_guide_service.dart';

const _sampleGuides = [
  {
    'id': 'tops-chest',
    'measurement_key': 'chest_cm',
    'title': 'Lingkar dada',
    'instruction': 'Lingkarkan pita ukur pada bagian dada.',
    'unit': 'cm',
    'category': 'tops',
    'sort_order': 1,
  },
];

http.Response _jsonResponse(Object data) {
  return http.Response(
    jsonEncode(data),
    200,
    headers: {'content-type': 'application/json; charset=utf-8'},
  );
}

MeasurementGuideService _service(http.Client client) {
  return MeasurementGuideService(
    client: client,
    baseUrl: 'https://example.supabase.co',
    publishableKey: 'sb_publishable_test_key',
  );
}

Widget _screen(http.Client client) {
  return MaterialApp(
    home: MeasurementGuideScreen(
      repository: MeasurementGuideRepository(_service(client)),
    ),
  );
}

void main() {
  testWidgets('menampilkan loading lalu panduan dari REST GET', (tester) async {
    final responseCompleter = Completer<http.Response>();

    final client = MockClient((request) {
      expect(request.method, 'GET');
      expect(request.url.path, '/rest/v1/measurement_guides');
      expect(request.url.queryParameters['category'], 'eq.tops');
      expect(request.url.queryParameters['is_published'], 'eq.true');
      expect(request.headers['apikey'], 'sb_publishable_test_key');

      return responseCompleter.future;
    });

    await tester.pumpWidget(_screen(client));

    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    expect(find.text('Memuat panduan...'), findsOneWidget);

    responseCompleter.complete(_jsonResponse(_sampleGuides));

    await tester.pumpAndSettle();

    expect(find.text('Lingkar dada'), findsOneWidget);
    expect(find.text('Lingkarkan pita ukur pada bagian dada.'), findsOneWidget);
    expect(find.byType(CircularProgressIndicator), findsNothing);
  });

  testWidgets(
    'menampilkan keadaan kosong ketika API mengembalikan daftar kosong',
    (tester) async {
      final client = MockClient((_) async => _jsonResponse([]));

      await tester.pumpWidget(_screen(client));
      await tester.pumpAndSettle();

      expect(find.text('Belum ada panduan'), findsOneWidget);
      expect(find.text('Panduan gagal dimuat'), findsNothing);
    },
  );

  testWidgets('menampilkan error dan berhasil setelah coba lagi', (
    tester,
  ) async {
    var requestCount = 0;

    final client = MockClient((_) async {
      requestCount++;

      if (requestCount == 1) {
        return http.Response('Service unavailable', 503);
      }

      return _jsonResponse(_sampleGuides);
    });

    await tester.pumpWidget(_screen(client));
    await tester.pumpAndSettle();

    expect(find.text('Panduan gagal dimuat'), findsOneWidget);
    expect(find.text('Coba lagi'), findsOneWidget);

    await tester.tap(find.text('Coba lagi'));
    await tester.pumpAndSettle();

    expect(requestCount, 2);
    expect(find.text('Lingkar dada'), findsOneWidget);
    expect(find.text('Panduan gagal dimuat'), findsNothing);
  });

  test('menolak respons JSON yang bukan daftar', () async {
    final client = MockClient(
      (_) async => _jsonResponse({'message': 'Format tidak sesuai'}),
    );

    final service = _service(client);
    addTearDown(service.dispose);

    await expectLater(service.fetchGuides(), throwsA(isA<FormatException>()));
  });
}
