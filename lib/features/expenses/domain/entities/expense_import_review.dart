class ExpenseReviewItem {
  const ExpenseReviewItem({
    required this.id,
    required this.title,
    required this.category,
    required this.amountKes,
    required this.occurredAt,
    required this.confidence,
    required this.rawMessage,
  });

  final int id;
  final String title;
  final String category;
  final double amountKes;
  final DateTime occurredAt;
  final double confidence;
  final String rawMessage;
}

class ExpenseQuarantineItem {
  const ExpenseQuarantineItem({
    required this.id,
    required this.reason,
    required this.confidence,
    required this.rawMessage,
    required this.createdAt,
  });

  final int id;
  final String reason;
  final double confidence;
  final String rawMessage;
  final DateTime createdAt;
}

class ExpenseImportMetrics {
  const ExpenseImportMetrics({
    required this.reviewQueueCount,
    required this.quarantineCount,
    required this.retryQueueCount,
    required this.failedQueueCount,
  });

  final int reviewQueueCount;
  final int quarantineCount;
  final int retryQueueCount;
  final int failedQueueCount;
}
