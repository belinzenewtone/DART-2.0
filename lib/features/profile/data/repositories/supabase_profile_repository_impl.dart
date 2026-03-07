import 'package:dart_2_0/data/remote/supabase/supabase_polling.dart';
import 'package:dart_2_0/features/profile/domain/entities/user_profile.dart';
import 'package:dart_2_0/features/profile/domain/repositories/profile_repository.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class SupabaseProfileRepositoryImpl implements ProfileRepository {
  SupabaseProfileRepositoryImpl(this._client);

  final SupabaseClient _client;

  @override
  Stream<UserProfile> watchProfile() => pollStream(_loadProfile);

  @override
  Future<void> updateProfile({
    required String name,
    required String email,
    required String phone,
  }) {
    final userId = _requireUserId();
    return _client.from('user_profile').upsert({
      'id': userId,
      'name': name,
      'email': email,
      'phone': phone,
      'member_since_label': _memberSinceLabel(),
      'verified': true,
    });
  }

  @override
  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    final email = _client.auth.currentUser?.email;
    if (email == null || email.isEmpty) {
      throw Exception('Sign in is required.');
    }
    await _client.auth.signInWithPassword(
      email: email,
      password: currentPassword,
    );
    await _client.auth.updateUser(UserAttributes(password: newPassword));
  }

  Future<UserProfile> _loadProfile() async {
    final user = _requireUser();
    final row = await _client
        .from('user_profile')
        .select('name,email,phone,member_since_label,verified')
        .eq('id', user.id)
        .maybeSingle();
    if (row == null) {
      final initialName = '${user.userMetadata?['name'] ?? ''}'.trim();
      final initialPhone = '${user.userMetadata?['phone'] ?? ''}'.trim();
      await updateProfile(
        name: initialName.isEmpty
            ? _defaultNameFromEmail(user.email)
            : initialName,
        email: user.email ?? '',
        phone: initialPhone.isEmpty ? '-' : initialPhone,
      );
      return UserProfile(
        name: initialName.isEmpty
            ? _defaultNameFromEmail(user.email)
            : initialName,
        email: user.email ?? '',
        phone: initialPhone.isEmpty ? '-' : initialPhone,
        memberSinceLabel: _memberSinceLabel(),
        verified: user.emailConfirmedAt != null,
      );
    }
    return UserProfile(
      name: '${row['name'] ?? ''}',
      email: '${row['email'] ?? ''}',
      phone: '${row['phone'] ?? ''}',
      memberSinceLabel: '${row['member_since_label'] ?? ''}',
      verified: row['verified'] == true,
    );
  }

  User _requireUser() {
    final user = _client.auth.currentUser;
    if (user == null) {
      throw Exception('Sign in is required.');
    }
    return user;
  }

  String _requireUserId() => _requireUser().id;

  String _defaultNameFromEmail(String? email) {
    final value = email ?? '';
    if (!value.contains('@')) {
      return 'User';
    }
    return value.split('@').first;
  }

  String _memberSinceLabel() {
    final createdAt = _client.auth.currentUser?.createdAt;
    final parsed = DateTime.tryParse(createdAt ?? '') ?? DateTime.now();
    const weekdays = [
      'Monday',
      'Tuesday',
      'Wednesday',
      'Thursday',
      'Friday',
      'Saturday',
      'Sunday'
    ];
    const months = [
      'January',
      'February',
      'March',
      'April',
      'May',
      'June',
      'July',
      'August',
      'September',
      'October',
      'November',
      'December',
    ];
    final weekday = weekdays[parsed.weekday - 1];
    final month = months[parsed.month - 1];
    final day = parsed.day.toString().padLeft(2, '0');
    return '$weekday, $month $day, ${parsed.year}';
  }
}
