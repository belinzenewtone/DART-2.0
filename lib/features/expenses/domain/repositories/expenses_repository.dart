import 'package:beltech/features/expenses/domain/entities/expense_item.dart';
import 'package:beltech/features/expenses/domain/entities/expense_import_review.dart';

abstract class ExpensesRepository {
  Stream<ExpensesSnapshot> watchSnapshot();

  Future<void> addManualTransaction({
    required String title,
    required String category,
    required double amountKes,
    DateTime? occurredAt,
  });

  Future<void> updateTransaction({
    required int transactionId,
    required String title,
    required String category,
    required double amountKes,
    required DateTime occurredAt,
  });

  Future<void> deleteTransaction(int transactionId);

  Future<int> importSmsMessages(List<String> rawMessages, {DateTime? from});

  Future<int> importFromDevice({DateTime? from});

  Future<ExpenseImportMetrics> fetchImportMetrics();

  Future<List<ExpenseReviewItem>> fetchReviewQueue({int limit = 20});

  Future<List<ExpenseQuarantineItem>> fetchQuarantineItems({int limit = 20});

  Future<void> resolveReviewItem({
    required int reviewId,
    required bool approve,
  });

  Future<void> dismissQuarantineItem(int quarantineId);
}
