class IncomeItem {
  const IncomeItem({
    required this.id,
    required this.title,
    required this.amountKes,
    required this.receivedAt,
    required this.source,
  });

  final int id;
  final String title;
  final double amountKes;
  final DateTime receivedAt;
  final String source;
}
