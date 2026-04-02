enum SuperEntryKind { task, event }

enum SuperEntryPriority { high, medium, low }

enum SuperEntryEventType { work, personal, finance, health, general }

class SuperEntryInput {
  const SuperEntryInput({
    required this.kind,
    required this.title,
    required this.description,
    this.priority,
    this.dueAt,
    this.startAt,
    this.endAt,
    this.eventType,
    this.reminderEnabled = false,
    this.reminderMinutesBefore = 30,
  });

  final SuperEntryKind kind;
  final String title;
  final String? description;
  final SuperEntryPriority? priority;
  final DateTime? dueAt;
  final DateTime? startAt;
  final DateTime? endAt;
  final SuperEntryEventType? eventType;
  final bool reminderEnabled;
  final int reminderMinutesBefore;
}
