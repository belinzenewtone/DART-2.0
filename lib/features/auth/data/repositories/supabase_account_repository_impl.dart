import 'package:beltech/features/auth/domain/entities/account_session.dart';
import 'package:beltech/features/auth/domain/repositories/account_repository.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class SupabaseAccountRepositoryImpl implements AccountRepository {
  SupabaseAccountRepositoryImpl(this._client);

  final SupabaseClient _client;

  @override
  Stream<AccountSession> watchSession() {
    return Stream<AccountSession>.multi((controller) {
      // Only emit synchronously when we already have a confirmed current user
      // (e.g. tab-switch resume where the session is known).  On a cold start
      // after the process was killed, Supabase restores the session
      // asynchronously, so currentUser is null here even though a valid stored
      // session exists.  Emitting unauthenticated in that case causes AuthGate
      // to flash the sign-in screen before the real session arrives.
      //
      // By NOT emitting when currentUser is null we stay in the
      // StreamProvider's loading state (AuthLoadingScreen) until
      // onAuthStateChange fires — which Supabase always does on startup,
      // either with the restored session or with a SignedOut event.
      final current = _client.auth.currentUser;
      if (current != null) {
        controller.add(_mapUser(current));
      }
      final subscription = _client.auth.onAuthStateChange.listen((event) {
        controller.add(_mapUser(event.session?.user));
      });
      controller.onCancel = subscription.cancel;
    });
  }

  @override
  AccountSession currentSession() {
    return _mapUser(_client.auth.currentUser);
  }

  @override
  Future<void> signIn({
    required String email,
    required String password,
  }) async {
    await _client.auth.signInWithPassword(
      email: email,
      password: password,
    );
  }

  @override
  Future<void> signUp({
    required String name,
    required String email,
    required String phone,
    required String password,
  }) async {
    final response = await _client.auth.signUp(
      email: email,
      password: password,
      data: {
        'name': name,
        'phone': phone,
      },
    );
    if (response.session == null) {
      await _client.auth.signInWithPassword(email: email, password: password);
    }
  }

  @override
  Future<void> signOut() {
    return _client.auth.signOut();
  }

  AccountSession _mapUser(User? user) {
    if (user == null) {
      return AccountSession.unauthenticated;
    }
    return AccountSession(
      isAuthenticated: true,
      userId: user.id,
      email: user.email,
      displayName: '${user.userMetadata?['name'] ?? ''}'.trim().isEmpty
          ? user.email
          : '${user.userMetadata?['name']}',
    );
  }
}
