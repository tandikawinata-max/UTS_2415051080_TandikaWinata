import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:usize/config/app_configuration.dart';
import 'package:usize/screens/app_startup.dart';

String legacyKey(String role) =>
    'header.${base64Url.encode(utf8.encode(jsonEncode({'role': role})))}.signature';

void main() {
  test('configuration accepts publishable keys', () {
    for (final key in ['sb_publishable_test-only', 'sb_publishable_Abc_123']) {
      expect(
        AppConfiguration(
          supabaseUrl: 'https://project.supabase.co',
          supabasePublishableKey: key,
        ).validate,
        returnsNormally,
      );
    }
  });
  test('configuration rejects missing, malformed and privileged keys', () {
    for (final key in [
      '',
      'replace-me',
      'sb_secret_test-only',
      legacyKey('anon'),
      legacyKey('service_role'),
      'a.invalid.c',
    ]) {
      expect(
        AppConfiguration(
          supabaseUrl: 'https://project.supabase.co',
          supabasePublishableKey: key,
        ).validate,
        throwsA(isA<AppConfigurationException>()),
      );
    }
    expect(
      AppConfiguration.fromJson({'SUPABASE_URL': 1}).validate,
      throwsA(isA<AppConfigurationException>()),
    );
  });
  test('configuration rejects invalid or credential-bearing URLs', () {
    for (final url in [
      '',
      'project.supabase.co',
      'http://project.supabase.co',
      'https://user:password@project.supabase.co',
      'https://project.supabase.co?key=hidden',
      'https://project.supabase.co/rest/v1',
      ' https://project.supabase.co',
    ]) {
      expect(
        AppConfiguration(
          supabaseUrl: url,
          supabasePublishableKey: 'sb_publishable_test-only',
        ).validate,
        throwsA(isA<AppConfigurationException>()),
      );
    }
  });
  testWidgets('startup waits for initialization before opening the app', (
    tester,
  ) async {
    final pending = Completer<void>();
    var calls = 0;
    await tester.pumpWidget(
      AppStartup(
        initialize: () {
          calls++;
          return pending.future;
        },
        child: const MaterialApp(home: Text('App siap')),
      ),
    );
    await tester.pump();
    expect(find.text('Membuka Usize...'), findsOneWidget);
    expect(find.text('App siap'), findsNothing);
    expect(calls, 1);
    pending.complete();
    await tester.pumpAndSettle();
    expect(find.text('App siap'), findsOneWidget);
  });
  testWidgets(
    'startup failure hides details and retry prevents duplicate initialization',
    (tester) async {
      var calls = 0;
      final retry = Completer<void>();
      await tester.pumpWidget(
        AppStartup(
          initialize: () {
            calls++;
            if (calls == 1) throw StateError('private implementation detail');
            return retry.future;
          },
          child: const MaterialApp(home: Text('App siap')),
        ),
      );
      await tester.pumpAndSettle();
      expect(
        find.textContaining('private implementation detail'),
        findsNothing,
      );
      await tester.tap(find.byKey(const ValueKey('retryStartup')));
      await tester.tap(find.byKey(const ValueKey('retryStartup')));
      await tester.pump();
      expect(find.byKey(const ValueKey('retryStartup')), findsNothing);
      expect(calls, 2);
      retry.complete();
      await tester.pumpAndSettle();
      expect(find.text('App siap'), findsOneWidget);
    },
  );
  testWidgets(
    'invalid build configuration explains failure without exposing values',
    (tester) async {
      await tester.pumpWidget(
        AppStartup(
          initialize: () => throw const AppConfigurationException(
            'private configuration detail',
          ),
          child: const MaterialApp(home: Text('App siap')),
        ),
      );
      await tester.pumpAndSettle();
      expect(
        find.textContaining('Konfigurasi aplikasi belum sesuai'),
        findsOneWidget,
      );
      expect(find.textContaining('private configuration detail'), findsNothing);
      expect(find.byKey(const ValueKey('retryStartup')), findsNothing);
      expect(find.text('App siap'), findsNothing);
    },
  );
  testWidgets('late startup completion after closing the screen is ignored', (
    tester,
  ) async {
    final pending = Completer<void>();
    await tester.pumpWidget(
      AppStartup(
        initialize: () => pending.future,
        child: const SizedBox.shrink(),
      ),
    );
    await tester.pump();
    await tester.pumpWidget(const SizedBox.shrink());
    pending.complete();
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });
}
