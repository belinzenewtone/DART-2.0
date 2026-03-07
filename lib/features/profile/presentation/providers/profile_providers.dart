import 'dart:async';
import 'dart:typed_data';

import 'package:dart_2_0/core/di/repository_providers.dart';
import 'package:dart_2_0/features/profile/domain/entities/user_profile.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final profileProvider = StreamProvider<UserProfile>(
  (ref) => ref.watch(profileRepositoryProvider).watchProfile(),
);

class ProfileWriteController extends AutoDisposeAsyncNotifier<void> {
  @override
  FutureOr<void> build() {}

  Future<void> updateProfile({
    required String name,
    required String email,
    required String phone,
  }) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      await ref.read(profileRepositoryProvider).updateProfile(
            name: name,
            email: email,
            phone: phone,
          );
    });
  }

  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      await ref.read(profileRepositoryProvider).changePassword(
            currentPassword: currentPassword,
            newPassword: newPassword,
          );
    });
  }

  Future<void> updateAvatar({
    required Uint8List bytes,
    required String fileExtension,
  }) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      await ref.read(profileRepositoryProvider).updateAvatar(
            bytes: bytes,
            fileExtension: fileExtension,
          );
    });
  }
}

final profileWriteControllerProvider =
    AutoDisposeAsyncNotifierProvider<ProfileWriteController, void>(
  ProfileWriteController.new,
);
