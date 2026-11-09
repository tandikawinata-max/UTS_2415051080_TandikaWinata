import '../services/session_service.dart';

abstract class SessionRepository {
  String? get currentUserId;

  Stream<String?> get userChanges;

  Future<void> signIn({required String email, required String password});

  Future<void> signOut();
}

class SupabaseSessionRepository implements SessionRepository {
  final SessionService _service;

  SupabaseSessionRepository(this._service);

  @override
  String? get currentUserId => _service.currentUserId;

  @override
  Stream<String?> get userChanges => _service.userChanges;

  @override
  Future<void> signIn({required String email, required String password}) {
    return _service.signIn(email: email, password: password);
  }

  @override
  Future<void> signOut() {
    return _service.signOut();
  }
}
