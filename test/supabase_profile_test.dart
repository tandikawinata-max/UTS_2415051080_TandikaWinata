import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:usize/models/body_measurement.dart';
import 'package:usize/providers/session_provider.dart';
import 'package:usize/repositories/session_repository.dart';

class FakeSessionRepository implements SessionRepository {
  final _changes = StreamController<String?>.broadcast();

  @override
  String? currentUserId;

  bool failLogin = false;

  @override
  Stream<String?> get userChanges => _changes.stream;

  @override
  Future<void> signIn({required String email, required String password}) async {
    if (failLogin) {
      throw StateError('Login ditolak.');
    }

    currentUserId = 'user-a';
    _changes.add(currentUserId);
  }

  @override
  Future<void> signOut() async {
    currentUserId = null;
    _changes.add(null);
  }

  void emitStreamError() {
    _changes.addError(StateError('Koneksi terputus.'));
  }

  Future<void> close() => _changes.close();
}

void main() {
  test('membaca angka dan kolom opsional dari JSON Supabase', () {
    final measurement = BodyMeasurement.fromJson({
      'id': 'profile-a',
      'user_id': 'user-a',
      'label': 'Profil Akun A',
      'chest_cm': 94,
      'waist_cm': 80.5,
      'hip_cm': null,
      'measured_at': '2026-11-09T12:00:00Z',
    });

    expect(measurement.userId, 'user-a');
    expect(measurement.chestCm, 94.0);
    expect(measurement.waistCm, 80.5);
    expect(measurement.hipCm, isNull);
    expect(measurement.shoulderWidthCm, isNull);
    expect(measurement.measuredAt.toUtc(), DateTime.utc(2026, 11, 9, 12));
  });

  group('SessionProvider', () {
    late FakeSessionRepository repository;
    late SessionProvider provider;

    setUp(() {
      repository = FakeSessionRepository();
      provider = SessionProvider(repository);
    });

    tearDown(() async {
      provider.dispose();
      await repository.close();
    });

    test('login menyimpan identitas dan logout menghapusnya', () async {
      expect(provider.userId, isNull);

      final signedIn = await provider.signIn(
        email: 'user@example.com',
        password: 'password-untuk-tes',
      );

      expect(signedIn, isTrue);
      expect(provider.userId, 'user-a');
      expect(provider.isBusy, isFalse);

      final signedOut = await provider.signOut();

      expect(signedOut, isTrue);
      expect(provider.userId, isNull);
      expect(provider.isBusy, isFalse);
    });

    test('login gagal menampilkan pesan tanpa membuka sesi', () async {
      repository.failLogin = true;

      final success = await provider.signIn(
        email: 'user@example.com',
        password: 'password-salah',
      );

      expect(success, isFalse);
      expect(provider.userId, isNull);
      expect(provider.errorMessage, isNotNull);
      expect(provider.isBusy, isFalse);
    });

    test('error stream sesi ditangani', () async {
      repository.emitStreamError();

      await Future<void>.delayed(Duration.zero);

      expect(provider.errorMessage, isNotNull);
    });
  });
}
