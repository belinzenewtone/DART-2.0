import 'package:dart_2_0/features/income/domain/entities/income_item.dart';

abstract class IncomeRepository {
  Stream<List<IncomeItem>> watchIncomes();

  Future<void> addIncome({
    required String title,
    required double amountKes,
    DateTime? receivedAt,
    String source = 'manual',
  });

  Future<void> updateIncome({
    required int incomeId,
    required String title,
    required double amountKes,
    required DateTime receivedAt,
  });

  Future<void> deleteIncome(int incomeId);
}
