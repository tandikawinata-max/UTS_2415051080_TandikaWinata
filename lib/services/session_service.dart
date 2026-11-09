import 'package:supabase_flutter/supabase_flutter.dart';

class SessionService {
  final SupabaseClient _client;

  SessionService(this._client);

  String? get currentUserId => _client.auth.currentUser?.id;

  Stream<String?> get userChanges {
    return _client.auth.onAuthStateChange.map(
      (event) => event.session?.user.id,
    );
  }

  Future<void> signIn({required String email, required String password}) async {
    final response = await _client.auth.signInWithPassword(
      email: email.trim(),
      password: password,
    );

    if (response.session == null) {
      throw StateError('Sesi login belum terbentuk.');
    }
  }

  Future<void> signOut() async {
    await _client.auth.signOut(scope: SignOutScope.local);
  }
}
