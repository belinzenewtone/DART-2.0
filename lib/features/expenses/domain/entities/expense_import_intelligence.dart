class PaybillProfile {
  const PaybillProfile({
    required this.id,
    required this.paybill,
    required this.displayName,
    required this.lastSeenAt,
    required this.usageCount,
  });

  final int id;
  final String paybill;
  final String displayName;
  final DateTime lastSeenAt;
  final int usageCount;
}

enum FulizaLifecycleKind { draw, repayment }

class FulizaLifecycleEvent {
  const FulizaLifecycleEvent({
    required this.id,
    required this.mpesaCode,
    required this.kind,
    required this.amountKes,
    required this.occurredAt,
  });

  final int id;
  final String mpesaCode;
  final FulizaLifecycleKind kind;
  final double amountKes;
  final DateTime occurredAt;
}
