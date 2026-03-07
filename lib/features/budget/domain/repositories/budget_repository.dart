import 'package:dart_2_0/features/budget/domain/entities/budget_snapshot.dart';
import 'package:dart_2_0/features/budget/domain/entities/budget_target.dart';

abstract class BudgetRepository {
  Stream<BudgetSnapshot> watchMonthlySnapshot(DateTime month);

  Future<void> upsertTarget({
    required String category,
    required double monthlyLimitKes,
  });

  Future<void> deleteTarget(int targetId);

  Future<List<BudgetTarget>> loadTargets();
}
