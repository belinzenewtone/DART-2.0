import 'package:dart_2_0/data/local/drift/app_drift_store.dart';
import 'package:dart_2_0/features/search/domain/entities/global_search_result.dart';
import 'package:dart_2_0/features/search/domain/repositories/global_search_repository.dart';

class GlobalSearchRepositoryImpl implements GlobalSearchRepository {
  GlobalSearchRepositoryImpl(this._store);

  final AppDriftStore _store;

  @override
  Future<List<GlobalSearchResult>> search(String query) async {
    final q = query.trim();
    if (q.isEmpty) {
      return const [];
    }
    await _store.ensureInitialized();
    final pattern = '%${q.toLowerCase()}%';
    final results = <GlobalSearchResult>[];

    final expenses = await _store.executor.runSelect(
      'SELECT title, category, amount FROM transactions '
      'WHERE LOWER(title) LIKE ? OR LOWER(category) LIKE ? '
      'ORDER BY occurred_at DESC LIMIT 15',
      [pattern, pattern],
    );
    for (final row in expenses) {
      results.add(
        GlobalSearchResult(
          kind: GlobalSearchKind.expense,
          primaryText: '${row['title'] ?? ''}',
          secondaryText: '${row['category'] ?? 'Other'}',
          trailingText: 'KES ${_asDouble(row['amount']).toStringAsFixed(2)}',
        ),
      );
    }

    final incomes = await _store.executor.runSelect(
      'SELECT title, amount, source FROM incomes WHERE LOWER(title) LIKE ? ORDER BY received_at DESC LIMIT 15',
      [pattern],
    );
    for (final row in incomes) {
      results.add(
        GlobalSearchResult(
          kind: GlobalSearchKind.income,
          primaryText: '${row['title'] ?? ''}',
          secondaryText: '${row['source'] ?? 'manual'}',
          trailingText: 'KES ${_asDouble(row['amount']).toStringAsFixed(2)}',
        ),
      );
    }

    final tasks = await _store.executor.runSelect(
      'SELECT title, description, completed FROM tasks '
      'WHERE LOWER(title) LIKE ? OR LOWER(COALESCE(description, \'\')) LIKE ? '
      'ORDER BY id DESC LIMIT 15',
      [pattern, pattern],
    );
    for (final row in tasks) {
      results.add(
        GlobalSearchResult(
          kind: GlobalSearchKind.task,
          primaryText: '${row['title'] ?? ''}',
          secondaryText: '${row['description'] ?? ''}',
          trailingText: _asInt(row['completed']) == 1 ? 'Done' : 'Pending',
        ),
      );
    }

    final events = await _store.executor.runSelect(
      'SELECT title, note FROM events WHERE LOWER(title) LIKE ? OR LOWER(COALESCE(note, \'\')) LIKE ? ORDER BY start_at DESC LIMIT 15',
      [pattern, pattern],
    );
    for (final row in events) {
      results.add(
        GlobalSearchResult(
          kind: GlobalSearchKind.event,
          primaryText: '${row['title'] ?? ''}',
          secondaryText: '${row['note'] ?? ''}',
          trailingText: 'Event',
        ),
      );
    }

    final budgets = await _store.executor.runSelect(
      'SELECT category, monthly_limit FROM budgets WHERE LOWER(category) LIKE ? ORDER BY category LIMIT 15',
      [pattern],
    );
    for (final row in budgets) {
      results.add(
        GlobalSearchResult(
          kind: GlobalSearchKind.budget,
          primaryText: '${row['category'] ?? ''}',
          secondaryText: 'Monthly budget',
          trailingText:
              'KES ${_asDouble(row['monthly_limit']).toStringAsFixed(2)}',
        ),
      );
    }

    final recurring = await _store.executor.runSelect(
      'SELECT title, kind, cadence FROM recurring_templates WHERE LOWER(title) LIKE ? ORDER BY id DESC LIMIT 15',
      [pattern],
    );
    for (final row in recurring) {
      results.add(
        GlobalSearchResult(
          kind: GlobalSearchKind.recurring,
          primaryText: '${row['title'] ?? ''}',
          secondaryText: '${row['kind'] ?? ''}',
          trailingText: '${row['cadence'] ?? ''}',
        ),
      );
    }

    return results;
  }

  int _asInt(Object? value) {
    if (value is int) {
      return value;
    }
    if (value is num) {
      return value.toInt();
    }
    return int.tryParse('$value') ?? 0;
  }

  double _asDouble(Object? value) {
    if (value is double) {
      return value;
    }
    if (value is num) {
      return value.toDouble();
    }
    return double.tryParse('$value') ?? 0;
  }
}
