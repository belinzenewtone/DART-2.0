import 'package:dart_2_0/features/profile/domain/entities/user_profile.dart';

abstract class ProfileRepository {
  Stream<UserProfile> watchProfile();

  Future<void> updateProfile({
    required String name,
    required String email,
    required String phone,
  });

  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
  });
}
