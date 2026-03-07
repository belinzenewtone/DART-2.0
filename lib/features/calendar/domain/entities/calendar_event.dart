class CalendarEvent {
  const CalendarEvent({
    required this.id,
    required this.title,
    required this.startAt,
    this.endAt,
    this.note,
  });

  final int id;
  final String title;
  final DateTime startAt;
  final DateTime? endAt;
  final String? note;
}
