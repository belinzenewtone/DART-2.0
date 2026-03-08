import 'package:dart_2_0/features/calendar/domain/entities/calendar_event.dart';

abstract class CalendarRepository {
  Stream<List<CalendarEvent>> watchEventsForDay(DateTime day);
  Stream<List<CalendarEvent>> watchEventsInRange(DateTime start, DateTime end);

  Future<void> addEvent({
    required String title,
    required DateTime startAt,
    CalendarEventPriority priority = CalendarEventPriority.medium,
    DateTime? endAt,
    String? note,
  });

  Future<void> updateEvent({
    required int eventId,
    required String title,
    required DateTime startAt,
    required CalendarEventPriority priority,
    DateTime? endAt,
    String? note,
  });

  Future<void> setCompleted({
    required int eventId,
    required bool completed,
  });

  Future<void> deleteEvent(int eventId);
}
