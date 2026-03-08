import 'package:dart_2_0/core/notifications/local_notification_service.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final localNotificationServiceProvider = Provider<LocalNotificationService>(
  (_) => LocalNotificationService(),
);

final notificationsEnabledProvider = FutureProvider<bool>(
  (ref) => ref.watch(localNotificationServiceProvider).isNotificationsEnabled(),
);

class NotificationPreferenceController extends AutoDisposeAsyncNotifier<void> {
  @override
  Future<void> build() async {}

  Future<void> setEnabled(bool enabled) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      await ref
          .read(localNotificationServiceProvider)
          .setNotificationsEnabled(enabled);
      ref.invalidate(notificationsEnabledProvider);
    });
  }
}

final notificationPreferenceControllerProvider =
    AutoDisposeAsyncNotifierProvider<NotificationPreferenceController, void>(
  NotificationPreferenceController.new,
);
