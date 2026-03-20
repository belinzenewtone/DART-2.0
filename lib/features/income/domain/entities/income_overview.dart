class IncomeTrendPoint {
  const IncomeTrendPoint({
    required this.label,
    required this.incomeKes,
  });

  final String label;
  final double incomeKes;
}

class IncomeOverview {
  const IncomeOverview({
    required this.totalIncomeKes,
    required this.currentMonthIncomeKes,
    required this.currentMonthExpenseKes,
    required this.netCashflowKes,
    required this.trend,
  });

  final double totalIncomeKes;
  final double currentMonthIncomeKes;
  final double currentMonthExpenseKes;
  final double netCashflowKes;
  final List<IncomeTrendPoint> trend;
}
