import 'package:beltech/core/di/repository_providers.dart';
import 'package:beltech/features/calendar/domain/entities/calendar_event.dart';
import 'package:beltech/features/calendar/domain/repositories/calendar_repository.dart';
import 'package:beltech/features/calendar/presentation/providers/calendar_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('agenda provider filters past events and sorts the next 14 days',
      () async {
    final repository = _FakeCalendarRepository([
      CalendarEvent(
        id: 1,
        title: 'Planning',
        startAt: DateTime(2026, 3, 22, 9),
        completed: false,
        priority: CalendarEventPriority.high,
        type: CalendarEventType.work,
      ),
      CalendarEvent(
        id: 2,
        title: 'Past review',
        startAt: DateTime(2026, 3, 20, 8),
        completed: false,
        priority: CalendarEventPriority.medium,
        type: CalendarEventType.personal,
      ),
      CalendarEvent(
        id: 3,
        title: 'Bills',
        startAt: DateTime(2026, 3, 25, 18),
        completed: false,
        priority: CalendarEventPriority.medium,
        type: CalendarEventType.finance,
      ),
      CalendarEvent(
        id: 4,
        title: 'Too far out',
        startAt: DateTime(2026, 4, 8, 12),
        completed: false,
        priority: CalendarEventPriority.low,
        type: CalendarEventType.general,
      ),
    ]);

    final container = ProviderContainer(
      overrides: [
        calendarRepositoryProvider.overrideWith((ref) => repository),
      ],
    );
    addTearDown(container.dispose);

    container.read(selectedDayProvider.notifier).state = DateTime(2026, 3, 21);

    final events = await container.read(agendaEventsProvider.future);

    expect(events.map((event) => event.id), [1, 3]);
    expect(events.first.title, 'Planning');
    expect(events.last.title, 'Bills');
  });
}

class _FakeCalendarRepository implements CalendarRepository {
  const _FakeCalendarRepository(this.events);

  final List<CalendarEvent> events;

  @override
  Future<void> addEvent({
    required String title,
    required DateTime startAt,
    CalendarEventPriority priority = CalendarEventPriority.medium,
    CalendarEventType type = CalendarEventType.general,
    DateTime? endAt,
    String? note,
  }) async {}

  @override
  Future<void> deleteEvent(int eventId) async {}

  @override
  Future<void> setCompleted({
    required int eventId,
    required bool completed,
  }) async {}

  @override
  Future<void> updateEvent({
    required int eventId,
    required String title,
    required DateTime startAt,
    required CalendarEventPriority priority,
    required CalendarEventType type,
    DateTime? endAt,
    String? note,
  }) async {}

  @override
  Stream<List<CalendarEvent>> watchEventsForDay(DateTime day) {
    final dayStart = DateTime(day.year, day.month, day.day);
    final nextDay = dayStart.add(const Duration(days: 1));
    return Stream.value(
      events
          .where(
            (event) =>
                !event.startAt.isBefore(dayStart) &&
                event.startAt.isBefore(nextDay),
          )
          .toList(),
    );
  }

  @override
  Stream<List<CalendarEvent>> watchEventsInRange(DateTime start, DateTime end) {
    return Stream.value(
      events
          .where(
            (event) =>
                !event.startAt.isBefore(start) && event.startAt.isBefore(end),
          )
          .toList(),
    );
  }
}
