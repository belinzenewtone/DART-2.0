import 'package:dart_2_0/core/theme/app_colors.dart';
import 'package:dart_2_0/core/widgets/category_chip.dart';
import 'package:dart_2_0/core/widgets/glass_card.dart';
import 'package:dart_2_0/features/expenses/domain/entities/expense_item.dart';
import 'package:dart_2_0/features/expenses/presentation/providers/expenses_providers.dart';
import 'package:dart_2_0/features/expenses/presentation/widgets/transaction_row.dart';
import 'package:flutter/material.dart';

class ExpensesSnapshotContent extends StatelessWidget {
  const ExpensesSnapshotContent({
    super.key,
    required this.snapshot,
    required this.selectedFilter,
    required this.busy,
    required this.onFilterChanged,
    required this.onEditExpense,
    required this.onDeleteExpense,
  });

  final ExpensesSnapshot snapshot;
  final ExpenseFilter selectedFilter;
  final bool busy;
  final ValueChanged<ExpenseFilter> onFilterChanged;
  final ValueChanged<ExpenseItem> onEditExpense;
  final ValueChanged<ExpenseItem> onDeleteExpense;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final transactions =
        _transactionsForFilter(snapshot.transactions, selectedFilter);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: _SummaryCard(
                title: 'Today',
                amount: 'KES ${snapshot.todayKes.toStringAsFixed(2)}',
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _SummaryCard(
                title: 'This Week',
                amount: 'KES ${snapshot.weekKes.toStringAsFixed(2)}',
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: ExpenseFilter.values.map((filter) {
            return CategoryChip(
              label: switch (filter) {
                ExpenseFilter.all => 'All',
                ExpenseFilter.today => 'Today',
                ExpenseFilter.week => 'This Week',
                ExpenseFilter.month => 'This Month',
              },
              selected: selectedFilter == filter,
              onTap: () => onFilterChanged(filter),
            );
          }).toList(),
        ),
        const SizedBox(height: 14),
        _CategoryCard(categories: snapshot.categories),
        const SizedBox(height: 16),
        Text('Transactions', style: textTheme.titleMedium),
        const SizedBox(height: 10),
        for (final tx in transactions.take(20)) ...[
          ExpenseTransactionRow(
            title: tx.title,
            subtitle:
                '${tx.category} · ${tx.occurredAt.month}/${tx.occurredAt.day}, ${tx.occurredAt.hour}:${tx.occurredAt.minute.toString().padLeft(2, '0')}',
            amount: 'KES ${tx.amountKes.toStringAsFixed(2)}',
            onEdit: () => onEditExpense(tx),
            onDelete: () => onDeleteExpense(tx),
            busy: busy,
          ),
          const SizedBox(height: 10),
        ],
      ],
    );
  }

  List<ExpenseItem> _transactionsForFilter(
      List<ExpenseItem> source, ExpenseFilter filter) {
    final now = DateTime.now();
    final dayStart = DateTime(now.year, now.month, now.day);
    final weekStart = dayStart.subtract(Duration(days: now.weekday - 1));
    final monthStart = DateTime(now.year, now.month, 1);
    return source.where((item) {
      switch (filter) {
        case ExpenseFilter.today:
          return !item.occurredAt.isBefore(dayStart);
        case ExpenseFilter.week:
          return !item.occurredAt.isBefore(weekStart);
        case ExpenseFilter.month:
          return !item.occurredAt.isBefore(monthStart);
        case ExpenseFilter.all:
          return true;
      }
    }).toList();
  }
}

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({
    required this.title,
    required this.amount,
  });

  final String title;
  final String amount;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: textTheme.bodyMedium),
          const SizedBox(height: 6),
          Text(amount, style: textTheme.titleMedium),
        ],
      ),
    );
  }
}

class _CategoryCard extends StatelessWidget {
  const _CategoryCard({required this.categories});

  final List<CategoryExpenseTotal> categories;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Categories', style: textTheme.titleMedium),
          const SizedBox(height: 12),
          for (final entry in categories.take(8)) ...[
            _CategoryRow(
              name: entry.category,
              amount: 'KES ${entry.totalKes.toStringAsFixed(2)}',
            ),
            const SizedBox(height: 10),
          ],
        ],
      ),
    );
  }
}

class _CategoryRow extends StatelessWidget {
  const _CategoryRow({
    required this.name,
    required this.amount,
  });

  final String name;
  final String amount;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Row(
      children: [
        const CircleAvatar(
          radius: 16,
          backgroundColor: AppColors.accentSoft,
          child:
              Icon(Icons.pie_chart_outline, color: AppColors.accent, size: 16),
        ),
        const SizedBox(width: 10),
        Expanded(child: Text(name, style: textTheme.bodyLarge)),
        Text(amount, style: textTheme.bodyLarge),
      ],
    );
  }
}
