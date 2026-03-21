import 'package:beltech/core/di/notification_providers.dart';
import 'package:beltech/core/di/repository_providers.dart';
import 'package:beltech/features/calendar/domain/entities/calendar_event.dart';
import 'package:beltech/features/calendar/presentation/providers/calendar_providers.dart';
import 'package:beltech/features/tasks/domain/entities/task_item.dart';
import 'package:beltech/features/tasks/presentation/providers/tasks_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'reminder_integration_fakes.dart';

void main() {
  test('task add/update triggers schedule and cancel hooks', () async {
    final tasksRepo = FakeTasksRepository();
    final notifications = FakeLocalNotificationService();
    final container = ProviderContainer(
      overrides: [
        tasksRepositoryProvider.overrideWithValue(tasksRepo),
        localNotificationServiceProvider.overrideWithValue(notifications),
      ],
    );
    addTearDown(container.dispose);

    final due = DateTime.now().add(const Duration(days: 1));
    await container.read(taskWriteControllerProvider.notifier).addTask(
          title: 'Reminder Task',
          dueDate: due,
          priority: TaskPriority.high,
        );

    expect(notifications.scheduledTaskIds, contains(1));

    await container.read(taskWriteControllerProvider.notifier).updateTask(
          taskId: 1,
          title: 'Reminder Task',
          dueDate: null,
          priority: TaskPriority.high,
        );

    expect(notifications.canceledTaskIds, contains(1));
  });

  test('event add/delete triggers schedule and cancel hooks', () async {
    final calendarRepo = FakeCalendarRepository();
    final notifications = FakeLocalNotificationService();
    final container = ProviderContainer(
      overrides: [
        calendarRepositoryProvider.overrideWithValue(calendarRepo),
        localNotificationServiceProvider.overrideWithValue(notifications),
      ],
    );
    addTearDown(container.dispose);

    final day = DateTime.now().add(const Duration(days: 1));
    final start = DateTime(day.year, day.month, day.day, 11);
    await container.read(calendarWriteControllerProvider.notifier).addEvent(
          title: 'Team Call',
          startAt: start,
          priority: CalendarEventPriority.medium,
          type: CalendarEventType.work,
          endAt: start.add(const Duration(hours: 1)),
          note: 'Planning',
        );

    expect(notifications.scheduledEventIds, contains(1));

    await container
        .read(calendarWriteControllerProvider.notifier)
        .deleteEvent(1);
    expect(notifications.canceledEventIds, contains(1));
  });
}
