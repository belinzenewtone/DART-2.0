class ExpenseItem {
  const ExpenseItem({
    required this.id,
    required this.title,
    required this.category,
    required this.amountKes,
    required this.occurredAt,
  });

  final int id;
  final String title;
  final String category;
  final double amountKes;
  final DateTime occurredAt;
}

class CategoryExpenseTotal {
  const CategoryExpenseTotal({
    required this.category,
    required this.totalKes,
  });

  final String category;
  final double totalKes;
}

class ExpensesSnapshot {
  const ExpensesSnapshot({
    required this.todayKes,
    required this.weekKes,
    required this.categories,
    required this.transactions,
  });

  final double todayKes;
  final double weekKes;
  final List<CategoryExpenseTotal> categories;
  final List<ExpenseItem> transactions;
}
