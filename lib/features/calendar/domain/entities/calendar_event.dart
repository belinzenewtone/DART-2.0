enum CalendarEventPriority { high, medium, low }

enum CalendarEventType { work, personal, finance, health, general }

class CalendarEvent {
  const CalendarEvent({
    required this.id,
    required this.title,
    required this.startAt,
    required this.completed,
    required this.priority,
    this.type = CalendarEventType.general,
    this.endAt,
    this.note,
  });

  final int id;
  final String title;
  final DateTime startAt;
  final bool completed;
  final CalendarEventPriority priority;
  final CalendarEventType type;
  final DateTime? endAt;
  final String? note;
}

CalendarEventType calendarEventTypeFromRaw(String raw) {
  return switch (raw.trim().toLowerCase()) {
    'work' => CalendarEventType.work,
    'personal' => CalendarEventType.personal,
    'finance' => CalendarEventType.finance,
    'health' => CalendarEventType.health,
    _ => CalendarEventType.general,
  };
}

String calendarEventTypeToRaw(CalendarEventType type) {
  return type.name;
}
