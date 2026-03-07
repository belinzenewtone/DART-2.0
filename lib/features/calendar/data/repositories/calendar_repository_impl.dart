import 'package:dart_2_0/data/local/drift/app_drift_store.dart';
import 'package:dart_2_0/data/local/drift/app_drift_store_mutations.dart';
import 'package:dart_2_0/features/calendar/domain/entities/calendar_event.dart';
import 'package:dart_2_0/features/calendar/domain/repositories/calendar_repository.dart';

class CalendarRepositoryImpl implements CalendarRepository {
  CalendarRepositoryImpl(this._store);

  final AppDriftStore _store;

  @override
  Stream<List<CalendarEvent>> watchEventsForDay(DateTime day) {
    return _store.watchEventsForDay(day).map(
          (rows) => rows
              .map(
                (row) => CalendarEvent(
                  id: row.id,
                  title: row.title,
                  startAt: row.startAt,
                  endAt: row.endAt,
                  note: row.note,
                ),
              )
              .toList(),
        );
  }

  @override
  Future<void> addEvent({
    required String title,
    required DateTime startAt,
    DateTime? endAt,
    String? note,
  }) async {
    await _store.addEvent(
      title: title,
      startAt: startAt,
      endAt: endAt,
      note: note,
    );
  }

  @override
  Future<void> updateEvent({
    required int eventId,
    required String title,
    required DateTime startAt,
    DateTime? endAt,
    String? note,
  }) {
    return _store.updateEvent(
      id: eventId,
      title: title,
      startAt: startAt,
      endAt: endAt,
      note: note,
    );
  }

  @override
  Future<void> deleteEvent(int eventId) {
    return _store.deleteEvent(eventId);
  }
}
