import 'package:beltech/core/di/notification_providers.dart';
import 'package:beltech/core/di/repository_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

Color accentForTab(int tab) {
  const palette = [
    Color(0xFF2D7CFF),
    Color(0xFF45A3C9),
    Color(0xFF2AAE9D),
    Color(0xFF3A8AE8),
    Color(0xFFE4895E),
    Color(0xFF6D77E8),
    Color(0xFF3E91D6),
  ];
  return palette[tab % palette.length];
}

Future<void> cleanupNotificationReminders(WidgetRef ref) async {
  final notifications = ref.read(localNotificationServiceProvider);
  final tasksRepository = ref.read(tasksRepositoryProvider);
  final calendarRepository = ref.read(calendarRepositoryProvider);
  final tasks = await tasksRepository.watchTasks().first;
  final activeTaskIds = tasks
      .where((task) =>
          !task.completed &&
          task.dueDate != null &&
          task.dueDate!.isAfter(DateTime.now()))
      .map((task) => task.id);

  final from = DateTime.now().subtract(const Duration(days: 1));
  final to = DateTime.now().add(const Duration(days: 365 * 2));
  final events = await calendarRepository.watchEventsInRange(from, to).first;
  final activeEventIds = events
      .where(
          (event) => !event.completed && event.startAt.isAfter(DateTime.now()))
      .map((event) => event.id);

  await notifications.cleanupOrphanedReminders(
    activeTaskIds: activeTaskIds,
    activeEventIds: activeEventIds,
  );
}
