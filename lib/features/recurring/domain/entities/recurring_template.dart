enum RecurringKind {
  expense,
  income,
  task,
  event,
}

enum RecurringCadence {
  daily,
  weekly,
  monthly,
}

class RecurringTemplate {
  const RecurringTemplate({
    required this.id,
    required this.kind,
    required this.title,
    this.description,
    this.category,
    this.amountKes,
    this.priority,
    required this.cadence,
    required this.nextRunAt,
    required this.enabled,
  });

  final int id;
  final RecurringKind kind;
  final String title;
  final String? description;
  final String? category;
  final double? amountKes;
  final String? priority;
  final RecurringCadence cadence;
  final DateTime nextRunAt;
  final bool enabled;
}
