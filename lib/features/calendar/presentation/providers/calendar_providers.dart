import 'dart:async';

import 'package:dart_2_0/core/di/notification_providers.dart';
import 'package:dart_2_0/core/notifications/local_notification_service.dart';
import 'package:dart_2_0/core/di/repository_providers.dart';
import 'package:dart_2_0/features/calendar/domain/entities/calendar_event.dart';
import 'package:dart_2_0/features/calendar/domain/repositories/calendar_repository.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final visibleMonthProvider = StateProvider<DateTime>(
  (_) {
    final now = DateTime.now();
    return DateTime(now.year, now.month, 1);
  },
);

final selectedDayProvider = StateProvider<DateTime>((_) => DateTime.now());

final dayEventsProvider = StreamProvider<List<CalendarEvent>>(
  (ref) {
    final day = ref.watch(selectedDayProvider);
    return ref.watch(calendarRepositoryProvider).watchEventsForDay(day);
  },
);

final monthEventDaysProvider = StreamProvider<Set<int>>(
  (ref) {
    final visibleMonth = ref.watch(visibleMonthProvider);
    final monthStart = DateTime(visibleMonth.year, visibleMonth.month, 1);
    final monthEnd = DateTime(visibleMonth.year, visibleMonth.month + 1, 1);
    return ref
        .watch(calendarRepositoryProvider)
        .watchEventsInRange(monthStart, monthEnd)
        .map((events) => events.map((event) => event.startAt.day).toSet());
  },
);

class CalendarWriteController extends AutoDisposeAsyncNotifier<void> {
  @override
  FutureOr<void> build() {}

  Future<void> addQuickEvent(DateTime day) async {
    final start = DateTime(day.year, day.month, day.day, 14, 0);
    await addEvent(
      title: 'New Event',
      startAt: start,
      endAt: start.add(const Duration(hours: 1)),
      note: 'Created from Calendar tab',
    );
  }

  Future<void> addEvent({
    required String title,
    required DateTime startAt,
    CalendarEventPriority priority = CalendarEventPriority.medium,
    DateTime? endAt,
    String? note,
  }) async {
    final repository = ref.read(calendarRepositoryProvider);
    final notifications = ref.read(localNotificationServiceProvider);
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      await repository.addEvent(
        title: title,
        startAt: startAt,
        priority: priority,
        endAt: endAt,
        note: note,
      );
      await _scheduleCreatedEventReminder(
        repository: repository,
        notifications: notifications,
        title: title,
        startAt: startAt,
        note: note,
      );
    });
  }

  Future<void> updateEvent({
    required int eventId,
    required String title,
    required DateTime startAt,
    required CalendarEventPriority priority,
    DateTime? endAt,
    String? note,
  }) async {
    final repository = ref.read(calendarRepositoryProvider);
    final notifications = ref.read(localNotificationServiceProvider);
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      await repository.updateEvent(
        eventId: eventId,
        title: title,
        startAt: startAt,
        priority: priority,
        endAt: endAt,
        note: note,
      );
      await notifications.scheduleEventReminder(
        eventId: eventId,
        title: title,
        startAt: startAt,
      );
    });
  }

  Future<void> deleteEvent(int eventId) async {
    final repository = ref.read(calendarRepositoryProvider);
    final notifications = ref.read(localNotificationServiceProvider);
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      await notifications.cancelEventReminder(eventId);
      await repository.deleteEvent(eventId);
    });
  }

  Future<void> setEventCompleted({
    required int eventId,
    required bool completed,
  }) async {
    final repository = ref.read(calendarRepositoryProvider);
    final notifications = ref.read(localNotificationServiceProvider);
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      await repository.setCompleted(eventId: eventId, completed: completed);
      if (completed) {
        await notifications.cancelEventReminder(eventId);
      }
    });
  }

  Future<void> _scheduleCreatedEventReminder({
    required CalendarRepository repository,
    required LocalNotificationService notifications,
    required String title,
    required DateTime startAt,
    String? note,
  }) async {
    try {
      final dayStart = DateTime(startAt.year, startAt.month, startAt.day);
      final events = await repository.watchEventsForDay(dayStart).first;
      final created = events.where((event) {
        final sameNote = (event.note ?? '') == (note ?? '');
        return event.title == title &&
            event.startAt.isAtSameMomentAs(startAt) &&
            sameNote;
      }).firstOrNull;
      if (created == null) {
        return;
      }
      await notifications.scheduleEventReminder(
        eventId: created.id,
        title: created.title,
        startAt: created.startAt,
      );
    } catch (_) {
      return;
    }
  }
}

final calendarWriteControllerProvider =
    AutoDisposeAsyncNotifierProvider<CalendarWriteController, void>(
  CalendarWriteController.new,
);
