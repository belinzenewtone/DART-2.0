import 'package:dart_2_0/data/remote/supabase/supabase_parsers.dart';
import 'package:dart_2_0/features/search/domain/entities/global_search_result.dart';
import 'package:dart_2_0/features/search/domain/repositories/global_search_repository.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class SupabaseGlobalSearchRepositoryImpl implements GlobalSearchRepository {
  SupabaseGlobalSearchRepositoryImpl(this._client);

  final SupabaseClient _client;

  @override
  Future<List<GlobalSearchResult>> search(String query) async {
    final q = query.trim();
    if (q.isEmpty) {
      return const [];
    }
    final userId = _requireUserId();
    final results = <GlobalSearchResult>[];

    final txRows = await _client
        .from('transactions')
        .select('title,category,amount')
        .eq('owner_id', userId)
        .or('title.ilike.%$q%,category.ilike.%$q%')
        .limit(15);
    for (final row in (txRows as List).cast<Map<String, dynamic>>()) {
      results.add(
        GlobalSearchResult(
          kind: GlobalSearchKind.expense,
          primaryText: '${row['title'] ?? ''}',
          secondaryText: '${row['category'] ?? 'Other'}',
          trailingText: 'KES ${parseDouble(row['amount']).toStringAsFixed(2)}',
        ),
      );
    }

    final incomeRows = await _client
        .from('incomes')
        .select('title,amount,source')
        .eq('owner_id', userId)
        .ilike('title', '%$q%')
        .limit(15);
    for (final row in (incomeRows as List).cast<Map<String, dynamic>>()) {
      results.add(
        GlobalSearchResult(
          kind: GlobalSearchKind.income,
          primaryText: '${row['title'] ?? ''}',
          secondaryText: '${row['source'] ?? 'manual'}',
          trailingText: 'KES ${parseDouble(row['amount']).toStringAsFixed(2)}',
        ),
      );
    }

    final taskRows = await _client
        .from('tasks')
        .select('title,description,completed')
        .eq('owner_id', userId)
        .or('title.ilike.%$q%,description.ilike.%$q%')
        .limit(15);
    for (final row in (taskRows as List).cast<Map<String, dynamic>>()) {
      results.add(
        GlobalSearchResult(
          kind: GlobalSearchKind.task,
          primaryText: '${row['title'] ?? ''}',
          secondaryText: '${row['description'] ?? ''}',
          trailingText: row['completed'] == true ? 'Done' : 'Pending',
        ),
      );
    }

    final eventRows = await _client
        .from('events')
        .select('title,note')
        .eq('owner_id', userId)
        .or('title.ilike.%$q%,note.ilike.%$q%')
        .limit(15);
    for (final row in (eventRows as List).cast<Map<String, dynamic>>()) {
      results.add(
        GlobalSearchResult(
          kind: GlobalSearchKind.event,
          primaryText: '${row['title'] ?? ''}',
          secondaryText: '${row['note'] ?? ''}',
          trailingText: 'Event',
        ),
      );
    }

    final budgetRows = await _client
        .from('budgets')
        .select('category,monthly_limit')
        .eq('owner_id', userId)
        .ilike('category', '%$q%')
        .limit(15);
    for (final row in (budgetRows as List).cast<Map<String, dynamic>>()) {
      results.add(
        GlobalSearchResult(
          kind: GlobalSearchKind.budget,
          primaryText: '${row['category'] ?? ''}',
          secondaryText: 'Monthly budget',
          trailingText:
              'KES ${parseDouble(row['monthly_limit']).toStringAsFixed(2)}',
        ),
      );
    }

    final recurringRows = await _client
        .from('recurring_templates')
        .select('title,kind,cadence')
        .eq('owner_id', userId)
        .ilike('title', '%$q%')
        .limit(15);
    for (final row in (recurringRows as List).cast<Map<String, dynamic>>()) {
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

  String _requireUserId() {
    final userId = _client.auth.currentUser?.id;
    if (userId == null || userId.isEmpty) {
      throw Exception('Sign in is required.');
    }
    return userId;
  }
}
