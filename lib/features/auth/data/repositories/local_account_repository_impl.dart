import 'package:beltech/features/auth/domain/entities/account_session.dart';
import 'package:beltech/features/auth/domain/repositories/account_repository.dart';

class LocalAccountRepositoryImpl implements AccountRepository {
  const LocalAccountRepositoryImpl();

  @override
  Stream<AccountSession> watchSession() {
    return Stream.value(currentSession());
  }

  @override
  AccountSession currentSession() {
    return const AccountSession(
      isAuthenticated: true,
      userId: 'local-user',
      email: 'local@device',
      displayName: 'Local User',
    );
  }

  @override
  Future<void> signIn({
    required String email,
    required String password,
  }) async {}

  @override
  Future<void> signUp({
    required String name,
    required String email,
    required String phone,
    required String password,
  }) async {}

  @override
  Future<void> signOut() async {}
}
