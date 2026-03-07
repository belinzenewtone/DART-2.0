import 'package:dart_2_0/features/calendar/domain/entities/calendar_event.dart';

abstract class CalendarRepository {
  Stream<List<CalendarEvent>> watchEventsForDay(DateTime day);

  Future<void> addEvent({
    required String title,
    required DateTime startAt,
    DateTime? endAt,
    String? note,
  });

  Future<void> updateEvent({
    required int eventId,
    required String title,
    required DateTime startAt,
    DateTime? endAt,
    String? note,
  });

  Future<void> deleteEvent(int eventId);
}
