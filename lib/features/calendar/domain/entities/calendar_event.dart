enum CalendarEventPriority { high, medium, low }

class CalendarEvent {
  const CalendarEvent({
    required this.id,
    required this.title,
    required this.startAt,
    required this.completed,
    required this.priority,
    this.endAt,
    this.note,
  });

  final int id;
  final String title;
  final DateTime startAt;
  final bool completed;
  final CalendarEventPriority priority;
  final DateTime? endAt;
  final String? note;
}
