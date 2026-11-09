import 'dart:async';

import 'package:flutter/foundation.dart';

import '../repositories/session_repository.dart';

class SessionProvider extends ChangeNotifier {
  final SessionRepository _repository;

  late final StreamSubscription<String?> _subscription;

  String? _userId;
  String? _errorMessage;
  bool _isBusy = false;
  bool _isDisposed = false;

  SessionProvider(this._repository) {
    _userId = _repository.currentUserId;

    _subscription = _repository.userChanges.listen(
      (userId) {
        if (_isDisposed) return;

        _userId = userId;
        _errorMessage = null;
        notifyListeners();
      },
      onError: (Object error, StackTrace stackTrace) {
        if (_isDisposed) return;

        _errorMessage =
            'Sesi belum dapat diperbarui. '
            'Periksa koneksi internetmu.';
        notifyListeners();
      },
    );
  }

  String? get userId => _userId;
  String? get errorMessage => _errorMessage;
  bool get isBusy => _isBusy;

  Future<bool> signIn({required String email, required String password}) {
    return _perform(
      () => _repository.signIn(email: email.trim(), password: password),
      'Tidak dapat masuk. Periksa email, kata sandi, '
      'konfirmasi akun, dan koneksi internet.',
    );
  }

  Future<bool> signOut() {
    return _perform(
      _repository.signOut,
      'Belum berhasil keluar. Silakan coba lagi.',
    );
  }

  Future<bool> _perform(
    Future<void> Function() action,
    String failureMessage,
  ) async {
    if (_isBusy || _isDisposed) return false;

    _isBusy = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await action();

      if (_isDisposed) return false;

      _userId = _repository.currentUserId;
      return true;
    } catch (_) {
      if (!_isDisposed) {
        _userId = _repository.currentUserId;
        _errorMessage = failureMessage;
      }

      return false;
    } finally {
      if (!_isDisposed) {
        _isBusy = false;
        notifyListeners();
      }
    }
  }

  @override
  void dispose() {
    _isDisposed = true;
    unawaited(_subscription.cancel());
    super.dispose();
  }
}
