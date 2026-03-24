import 'package:beltech/core/theme/app_colors.dart';
import 'package:beltech/features/expenses/presentation/widgets/transaction_row.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Widget _wrap(Widget child) {
  return MaterialApp(
    theme: ThemeData.dark(),
    home: Scaffold(body: child),
  );
}

void main() {
  group('ExpenseTransactionRow', () {
    testWidgets('renders title, category and amount', (tester) async {
      await tester.pumpWidget(
        _wrap(
          ExpenseTransactionRow(
            dismissKey: 'expense-1',
            title: 'Coffee',
            amount: 'KES 320',
            category: 'Food',
            occurredAt: DateTime(2026, 3, 24, 8, 15),
            onEdit: () {},
            onDelete: () {},
            busy: false,
          ),
        ),
      );

      expect(find.text('Coffee'), findsOneWidget);
      expect(find.text('Food'), findsOneWidget);
      expect(find.text('KES 320'), findsOneWidget);
      expect(find.text('08:15'), findsOneWidget);
    });

    testWidgets('uses warning and danger swipe backgrounds', (tester) async {
      await tester.pumpWidget(
        _wrap(
          ExpenseTransactionRow(
            dismissKey: 'expense-2',
            title: 'Taxi',
            amount: 'KES 900',
            category: 'Transport',
            occurredAt: DateTime(2026, 3, 24, 19, 45),
            onEdit: () {},
            onDelete: () {},
            busy: false,
          ),
        ),
      );

      final dismissible = tester.widget<Dismissible>(find.byType(Dismissible));
      final start = dismissible.background as dynamic;
      final end = dismissible.secondaryBackground as dynamic;

      expect(start.color, AppColors.warningMuted);
      expect(end.color, AppColors.dangerMuted);
    });
  });
}
