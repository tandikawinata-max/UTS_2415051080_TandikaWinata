import 'dart:async';
import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:usize/models/analysis_history.dart';
import 'package:usize/services/analysis_history_service.dart';
import 'history_fixtures.dart';

const ownerA = '11111111-1111-4111-8111-111111111111';
const ownerB = '22222222-2222-4222-8222-222222222222';
Future<void> setUser(SupabaseClient client, String id) async {
  final expiry = DateTime.now().millisecondsSinceEpoch ~/ 1000 + 3600;
  String part(Object json) =>
      base64Url.encode(utf8.encode(jsonEncode(json))).replaceAll('=', '');
  await client.auth.setInitialSession(
    jsonEncode({
      'access_token':
          '${part({'alg': 'HS256'})}.${part({'sub': id, 'exp': expiry})}.test-signature',
      'refresh_token': 'test-refresh',
      'expires_in': 3600,
      'expires_at': expiry,
      'token_type': 'bearer',
      'user': {
        'id': id,
        'aud': 'authenticated',
        'app_metadata': {},
        'user_metadata': {},
        'created_at': '2026-01-01T00:00:00Z',
      },
    }),
  );
}

Future<SupabaseClient> testClient(
  Future<http.Response> Function(http.Request) handler,
) async {
  final client = SupabaseClient(
    'https://history.test',
    'test-key',
    httpClient: MockClient((request) async {
      final response = await handler(request);
      return http.Response.bytes(
        response.bodyBytes,
        response.statusCode,
        headers: response.headers,
        request: request,
      );
    }),
    authOptions: const AuthClientOptions(autoRefreshToken: false),
  );
  await setUser(client, ownerA);
  addTearDown(client.dispose);
  return client;
}

http.Response jsonResponse(Object? body, [int status = 200]) => http.Response(
  jsonEncode(body),
  status,
  headers: {'content-type': 'application/json'},
);
Map<String, dynamic> stored({String title = 'Kemeja linen'}) => {
  ...historyDraft(title: title).toJson(),
  'user_id': ownerA,
  'created_at': '2026-11-10T12:00:00Z',
};

void main() {
  test(
    'save sends owner and snapshot, leaves saved timestamp to database',
    () async {
      final client = await testClient((request) async {
        expect(request.method, 'POST');
        expect(request.url.path, '/rest/v1/fit_analyses');
        final body = jsonDecode(request.body) as Map;
        expect(body['user_id'], ownerA);
        expect(body['id'], historyResultId);
        expect(body.containsKey('created_at'), isFalse);
        expect(request.body.contains('/local/temporary.png'), isFalse);
        return jsonResponse(stored(), 201);
      });
      final row = await AnalysisHistoryService(
        client,
        ownerA,
      ).save(historyDraft());
      expect(row['title'], 'Kemeja linen');
    },
  );
  test(
    'retry after lost success uses insert conflict and confirms exact existing result',
    () async {
      var writes = 0;
      final client = await testClient((request) async {
        if (request.method == 'POST') {
          writes++;
          if (writes == 1) {
            throw http.ClientException('Reply lost after insert');
          }
          return jsonResponse({
            'code': '23505',
            'message': 'duplicate key',
            'details': null,
            'hint': null,
          }, 409);
        }
        expect(request.url.queryParameters['user_id'], 'eq.$ownerA');
        expect(request.url.queryParameters['id'], 'eq.$historyResultId');
        return jsonResponse([stored()]);
      });
      final service = AnalysisHistoryService(client, ownerA);
      await expectLater(
        service.save(historyDraft()),
        throwsA(isA<http.ClientException>()),
      );
      final confirmed = await service.save(historyDraft());
      expect(confirmed['id'], historyResultId);
      expect(writes, 2);
    },
  );
  test('conflicting ID never overwrites earlier payload', () async {
    final methods = <String>[];
    final client = await testClient((request) async {
      methods.add(request.method);
      return request.method == 'POST'
          ? jsonResponse({'code': '23505', 'message': 'duplicate key'}, 409)
          : jsonResponse([stored(title: 'Nama asli')]);
    });
    await expectLater(
      AnalysisHistoryService(client, ownerA).save(historyDraft()),
      throwsA(isA<AnalysisHistoryConflict>()),
    );
    expect(methods, ['POST', 'GET']);
  });
  test(
    'page query uses owner, stable cursor and bounded summary payload',
    () async {
      final client = await testClient((request) async {
        final query = request.url.queryParameters;
        expect(query['user_id'], 'eq.$ownerA');
        expect(query['limit'], '21');
        expect(query['order'], 'created_at.desc.nullslast,id.desc.nullslast');
        expect(query['or'], contains('id.lt.$historyResultId'));
        expect(query['select'], isNot(contains('payload')));
        return jsonResponse([]);
      });
      expect(
        await AnalysisHistoryService(client, ownerA).fetchPage(
          after: AnalysisHistoryCursor(DateTime.utc(2026), historyResultId),
        ),
        isEmpty,
      );
    },
  );
  test(
    'delete retry verifies absent row using the same owner and ID',
    () async {
      final methods = <String>[];
      final client = await testClient((request) async {
        methods.add(request.method);
        expect(request.url.queryParameters['user_id'], 'eq.$ownerA');
        expect(request.url.queryParameters['id'], 'eq.$historyResultId');
        return request.method == 'DELETE'
            ? jsonResponse(null)
            : jsonResponse([]);
      });
      await AnalysisHistoryService(client, ownerA).delete(historyResultId);
      expect(methods, ['DELETE', 'GET']);
    },
  );
  test('changed account rejects requests before sending', () async {
    var calls = 0;
    final client = await testClient((request) async {
      calls++;
      return jsonResponse([]);
    });
    final oldService = AnalysisHistoryService(client, ownerA);
    await setUser(client, ownerB);
    await expectLater(
      oldService.fetchPage(),
      throwsA(isA<AnalysisHistoryUnavailable>()),
    );
    await expectLater(
      oldService.save(historyDraft()),
      throwsA(isA<AnalysisHistoryUnavailable>()),
    );
    await expectLater(
      oldService.delete(historyResultId),
      throwsA(isA<AnalysisHistoryUnavailable>()),
    );
    expect(calls, 0);
  });
  test(
    'account change during read rejects late response from previous account',
    () async {
      final entered = Completer<void>();
      final release = Completer<void>();
      final client = await testClient((request) async {
        entered.complete();
        await release.future;
        return jsonResponse([stored()]);
      });
      final pending = AnalysisHistoryService(
        client,
        ownerA,
      ).findById(historyResultId);
      final check = expectLater(
        pending,
        throwsA(isA<AnalysisHistoryUnavailable>()),
      );
      await entered.future;
      await setUser(client, ownerB);
      release.complete();
      await check;
    },
  );
}
