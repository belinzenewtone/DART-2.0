import 'package:dart_2_0/core/notifications/local_notification_service.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final localNotificationServiceProvider = Provider<LocalNotificationService>(
  (_) => LocalNotificationService(),
);
